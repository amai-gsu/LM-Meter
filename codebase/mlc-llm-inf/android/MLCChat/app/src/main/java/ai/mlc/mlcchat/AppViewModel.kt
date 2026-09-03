package ai.mlc.mlcchat.inference

import ai.mlc.mlcllm.MLCEngine
import ai.mlc.mlcllm.OpenAIProtocol
import android.app.Application
import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.os.Environment
import android.widget.Toast
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.toMutableStateList
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.google.gson.Gson
import com.google.gson.annotations.SerializedName
import kotlinx.coroutines.launch
import java.io.File
import java.io.FileOutputStream
import java.net.URL
import java.nio.channels.Channels
import java.util.UUID
import java.util.concurrent.Executors
import kotlin.concurrent.thread
import ai.mlc.mlcllm.OpenAIProtocol.ChatCompletionMessage
import kotlinx.coroutines.*

/** Update 3/24/2025 **/
import com.google.gson.reflect.TypeToken
import android.util.Log
import java.lang.Thread.sleep
import java.io.FileWriter
import java.io.IOException
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import com.google.gson.GsonBuilder

import org.json.JSONObject   // Android stdlib

import android.os.Trace

fun loadPromptsFromAssets(context: Context): List<List<String>> {
    val inputStream = context.assets.open("prompts.json")
//    val inputStream = context.assets.open("prompts_hellaswag_seed8.json")
    val jsonString = inputStream.bufferedReader().use { it.readText() }
    val gson = Gson()
    return gson.fromJson(jsonString, Array<Array<String>>::class.java)
        .map { it.toList() }
}
/** Update 3/24/2025 **/

/** Update 3/28/2025 **/
//private val mlcEvents: HashMap<String, String> = HashMap()
private var mlcEvents: LinkedHashMap<String, String> = LinkedHashMap()
private var responseId = 0
private val dateFormat = SimpleDateFormat("yyyy-MM-dd_HH-mm-ss", Locale.US)
private val timestamp = dateFormat.format(Date())

//data class ProfileLogEntry(
//    val responseId: Int,
//    val modelId: String,
//    val prompt: String,
//    val response: String,
//    val prompt_tokens: Int,
//    val completion_tokens: Int,
//    val total_tokens: Int,
//    val prefill_tokens_per_s: Double,
//    val decode_tokens_per_s: Double
//)
data class ProfileLogEntry(
    @SerializedName("responseId") val responseId: Int,
    @SerializedName("modelId") val modelId: String,
    @SerializedName("prompt") val prompt: String,
    @SerializedName("response") val response: String,
    @SerializedName("prompt_tokens") val prompt_tokens: Int,
    @SerializedName("completion_tokens") val completion_tokens: Int,
    @SerializedName("total_tokens") val total_tokens: Int,
    @SerializedName("prefill_tokens_per_s") val prefill_tokens_per_s: Double,
    @SerializedName("decode_tokens_per_s") val decode_tokens_per_s: Double
)

/** Update 3/28/2025 **/

class AppViewModel(application: Application) : AndroidViewModel(application) {
    val modelList = emptyList<ModelState>().toMutableStateList()
    val chatState = ChatState()
    val modelSampleList = emptyList<ModelRecord>().toMutableStateList()
    private var showAlert = mutableStateOf(false)
    private var alertMessage = mutableStateOf("")
    private var appConfig = AppConfig(
        emptyList<String>().toMutableList(),
        emptyList<ModelRecord>().toMutableList()
    )
    private val application = getApplication<Application>()
    private val appDirFile = application.getExternalFilesDir("")
    private val gson = Gson()
    private val modelIdSet = emptySet<String>().toMutableSet()

    companion object {
        const val AppConfigFilename = "mlc-app-config.json"
        const val ModelConfigFilename = "mlc-chat-config.json"
        const val ParamsConfigFilename = "ndarray-cache.json"
        const val ModelUrlSuffix = "resolve/main/"
    }

    init {
        loadAppConfig()
    }

    fun isShowingAlert(): Boolean {
        return showAlert.value
    }

    fun errorMessage(): String {
        return alertMessage.value
    }

    fun dismissAlert() {
        require(showAlert.value)
        showAlert.value = false
    }

    fun copyError() {
        require(showAlert.value)
        val clipboard =
            application.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
        clipboard.setPrimaryClip(ClipData.newPlainText("MLCChat", errorMessage()))
    }

    private fun issueAlert(error: String) {
        showAlert.value = true
        alertMessage.value = error
    }

    fun requestDeleteModel(modelId: String) {
        deleteModel(modelId)
        issueAlert("Model: $modelId has been deleted")
    }


    private fun loadAppConfig() {
        val appConfigFile = File(appDirFile, AppConfigFilename)
        val jsonString: String = if (!appConfigFile.exists()) {
            application.assets.open(AppConfigFilename).bufferedReader().use { it.readText() }
        } else {
            appConfigFile.readText()
        }
        appConfig = gson.fromJson(jsonString, AppConfig::class.java)
        appConfig.modelLibs = emptyList<String>().toMutableList()
        modelList.clear()
        modelIdSet.clear()
        modelSampleList.clear()
        for (modelRecord in appConfig.modelList) {
            appConfig.modelLibs.add(modelRecord.modelLib)
            val modelDirFile = File(appDirFile, modelRecord.modelId)
            val modelConfigFile = File(modelDirFile, ModelConfigFilename)
            if (modelConfigFile.exists()) {
                val modelConfigString = modelConfigFile.readText()
                val modelConfig = gson.fromJson(modelConfigString, ModelConfig::class.java)
                modelConfig.modelId = modelRecord.modelId
                modelConfig.modelLib = modelRecord.modelLib
                modelConfig.estimatedVramBytes = modelRecord.estimatedVramBytes
                addModelConfig(modelConfig, modelRecord.modelUrl, true)
            } else {
                downloadModelConfig(
                    if (modelRecord.modelUrl.endsWith("/")) modelRecord.modelUrl else "${modelRecord.modelUrl}/",
                    modelRecord,
                    true
                )
            }
        }
    }

    private fun updateAppConfig(action: () -> Unit) {
        action()
        val jsonString = gson.toJson(appConfig)
        val appConfigFile = File(appDirFile, AppConfigFilename)
        appConfigFile.writeText(jsonString)
    }

    private fun addModelConfig(modelConfig: ModelConfig, modelUrl: String, isBuiltin: Boolean) {
        require(!modelIdSet.contains(modelConfig.modelId))
        modelIdSet.add(modelConfig.modelId)
        modelList.add(
            ModelState(
                modelConfig,
                modelUrl + if (modelUrl.endsWith("/")) "" else "/",
                File(appDirFile, modelConfig.modelId)
            )
        )
        if (!isBuiltin) {
            updateAppConfig {
                appConfig.modelList.add(
                    ModelRecord(
                        modelUrl,
                        modelConfig.modelId,
                        modelConfig.estimatedVramBytes,
                        modelConfig.modelLib
                    )
                )
            }
        }
    }

    private fun deleteModel(modelId: String) {
        val modelDirFile = File(appDirFile, modelId)
        modelDirFile.deleteRecursively()
        require(!modelDirFile.exists())
        modelIdSet.remove(modelId)
        modelList.removeIf { modelState -> modelState.modelConfig.modelId == modelId }
        updateAppConfig {
            appConfig.modelList.removeIf { modelRecord -> modelRecord.modelId == modelId }
        }
    }

    private fun isModelConfigAllowed(modelConfig: ModelConfig): Boolean {
        if (appConfig.modelLibs.contains(modelConfig.modelLib)) return true
        viewModelScope.launch {
            issueAlert("Model lib ${modelConfig.modelLib} is not supported.")
        }
        return false
    }


    private fun downloadModelConfig(
        modelUrl: String,
        modelRecord: ModelRecord,
        isBuiltin: Boolean
    ) {
        thread(start = true) {
            try {
                val url = URL("${modelUrl}${ModelUrlSuffix}${ModelConfigFilename}")
                val tempId = UUID.randomUUID().toString()
                val tempFile = File(
                    application.getExternalFilesDir(Environment.DIRECTORY_DOWNLOADS),
                    tempId
                )
                url.openStream().use {
                    Channels.newChannel(it).use { src ->
                        FileOutputStream(tempFile).use { fileOutputStream ->
                            fileOutputStream.channel.transferFrom(src, 0, Long.MAX_VALUE)
                        }
                    }
                }
                require(tempFile.exists())
                viewModelScope.launch {
                    try {
                        val modelConfigString = tempFile.readText()
                        val modelConfig = gson.fromJson(modelConfigString, ModelConfig::class.java)
                        modelConfig.modelId = modelRecord.modelId
                        modelConfig.modelLib = modelRecord.modelLib
                        modelConfig.estimatedVramBytes = modelRecord.estimatedVramBytes
                        if (modelIdSet.contains(modelConfig.modelId)) {
                            tempFile.delete()
                            issueAlert("${modelConfig.modelId} has been used, please consider another local ID")
                            return@launch
                        }
                        if (!isModelConfigAllowed(modelConfig)) {
                            tempFile.delete()
                            return@launch
                        }
                        val modelDirFile = File(appDirFile, modelConfig.modelId)
                        val modelConfigFile = File(modelDirFile, ModelConfigFilename)
                        tempFile.copyTo(modelConfigFile, overwrite = true)
                        tempFile.delete()
                        require(modelConfigFile.exists())
                        addModelConfig(modelConfig, modelUrl, isBuiltin)
                    } catch (e: Exception) {
                        viewModelScope.launch {
                            issueAlert("Add model failed: ${e.localizedMessage}")
                        }
                    }
                }
            } catch (e: Exception) {
                viewModelScope.launch {
                    issueAlert("Download model config failed: ${e.localizedMessage}")
                }
            }

        }
    }

    inner class ModelState(
        val modelConfig: ModelConfig,
        private val modelUrl: String,
        private val modelDirFile: File
    ) {
        var modelInitState = mutableStateOf(ModelInitState.Initializing)
        private var paramsConfig = ParamsConfig(emptyList())
        val progress = mutableStateOf(0)
        val total = mutableStateOf(1)
        val id: UUID = UUID.randomUUID()
        private val remainingTasks = emptySet<DownloadTask>().toMutableSet()
        private val downloadingTasks = emptySet<DownloadTask>().toMutableSet()
        private val maxDownloadTasks = 3
        private val gson = Gson()


        init {
            switchToInitializing()
        }

        private fun switchToInitializing() {
            val paramsConfigFile = File(modelDirFile, ParamsConfigFilename)
            if (paramsConfigFile.exists()) {
                loadParamsConfig()
                switchToIndexing()
            } else {
                downloadParamsConfig()
            }
        }

        private fun loadParamsConfig() {
            val paramsConfigFile = File(modelDirFile, ParamsConfigFilename)
            require(paramsConfigFile.exists())
            val jsonString = paramsConfigFile.readText()
            paramsConfig = gson.fromJson(jsonString, ParamsConfig::class.java)
        }

        private fun downloadParamsConfig() {
            thread(start = true) {
                val url = URL("${modelUrl}${ModelUrlSuffix}${ParamsConfigFilename}")
                val tempId = UUID.randomUUID().toString()
                val tempFile = File(modelDirFile, tempId)
                url.openStream().use {
                    Channels.newChannel(it).use { src ->
                        FileOutputStream(tempFile).use { fileOutputStream ->
                            fileOutputStream.channel.transferFrom(src, 0, Long.MAX_VALUE)
                        }
                    }
                }
                require(tempFile.exists())
                val paramsConfigFile = File(modelDirFile, ParamsConfigFilename)
                tempFile.renameTo(paramsConfigFile)
                require(paramsConfigFile.exists())
                viewModelScope.launch {
                    loadParamsConfig()
                    switchToIndexing()
                }
            }
        }

        fun handleStart() {
            switchToDownloading()
        }

        fun handlePause() {
            switchToPausing()
        }

        fun handleClear() {
            require(
                modelInitState.value == ModelInitState.Downloading ||
                        modelInitState.value == ModelInitState.Paused ||
                        modelInitState.value == ModelInitState.Finished
            )
            switchToClearing()
        }

        private fun switchToClearing() {
            if (modelInitState.value == ModelInitState.Paused) {
                modelInitState.value = ModelInitState.Clearing
                clear()
            } else if (modelInitState.value == ModelInitState.Finished) {
                modelInitState.value = ModelInitState.Clearing
                if (chatState.modelName.value == modelConfig.modelId) {
                    chatState.requestTerminateChat { clear() }
                } else {
                    clear()
                }
            } else {
                modelInitState.value = ModelInitState.Clearing
            }
        }

        fun handleDelete() {
            require(
                modelInitState.value == ModelInitState.Downloading ||
                        modelInitState.value == ModelInitState.Paused ||
                        modelInitState.value == ModelInitState.Finished
            )
            switchToDeleting()
        }

        private fun switchToDeleting() {
            if (modelInitState.value == ModelInitState.Paused) {
                modelInitState.value = ModelInitState.Deleting
                delete()
            } else if (modelInitState.value == ModelInitState.Finished) {
                modelInitState.value = ModelInitState.Deleting
                if (chatState.modelName.value == modelConfig.modelId) {
                    chatState.requestTerminateChat { delete() }
                } else {
                    delete()
                }
            } else {
                modelInitState.value = ModelInitState.Deleting
            }
        }

        private fun switchToIndexing() {
            modelInitState.value = ModelInitState.Indexing
            progress.value = 0
            total.value = modelConfig.tokenizerFiles.size + paramsConfig.paramsRecords.size
            for (tokenizerFilename in modelConfig.tokenizerFiles) {
                val file = File(modelDirFile, tokenizerFilename)
                if (file.exists()) {
                    ++progress.value
                } else {
                    remainingTasks.add(
                        DownloadTask(
                            URL("${modelUrl}${ModelUrlSuffix}${tokenizerFilename}"),
                            file
                        )
                    )
                }
            }
            for (paramsRecord in paramsConfig.paramsRecords) {
                val file = File(modelDirFile, paramsRecord.dataPath)
                if (file.exists()) {
                    ++progress.value
                } else {
                    remainingTasks.add(
                        DownloadTask(
                            URL("${modelUrl}${ModelUrlSuffix}${paramsRecord.dataPath}"),
                            file
                        )
                    )
                }
            }
            if (progress.value < total.value) {
                switchToPaused()
            } else {
                switchToFinished()
            }
        }

        private fun switchToDownloading() {
            modelInitState.value = ModelInitState.Downloading
            for (downloadTask in remainingTasks) {
                if (downloadingTasks.size < maxDownloadTasks) {
                    handleNewDownload(downloadTask)
                } else {
                    return
                }
            }
        }

        private fun handleNewDownload(downloadTask: DownloadTask) {
            require(modelInitState.value == ModelInitState.Downloading)
            require(!downloadingTasks.contains(downloadTask))
            downloadingTasks.add(downloadTask)
            thread(start = true) {
                val tempId = UUID.randomUUID().toString()
                val tempFile = File(modelDirFile, tempId)
                downloadTask.url.openStream().use {
                    Channels.newChannel(it).use { src ->
                        FileOutputStream(tempFile).use { fileOutputStream ->
                            fileOutputStream.channel.transferFrom(src, 0, Long.MAX_VALUE)
                        }
                    }
                }
                require(tempFile.exists())
                tempFile.renameTo(downloadTask.file)
                require(downloadTask.file.exists())
                viewModelScope.launch {
                    handleFinishDownload(downloadTask)
                }
            }
        }

        private fun handleNextDownload() {
            require(modelInitState.value == ModelInitState.Downloading)
            for (downloadTask in remainingTasks) {
                if (!downloadingTasks.contains(downloadTask)) {
                    handleNewDownload(downloadTask)
                    break
                }
            }
        }

        private fun handleFinishDownload(downloadTask: DownloadTask) {
            remainingTasks.remove(downloadTask)
            downloadingTasks.remove(downloadTask)
            ++progress.value
            require(
                modelInitState.value == ModelInitState.Downloading ||
                        modelInitState.value == ModelInitState.Pausing ||
                        modelInitState.value == ModelInitState.Clearing ||
                        modelInitState.value == ModelInitState.Deleting
            )
            if (modelInitState.value == ModelInitState.Downloading) {
                if (remainingTasks.isEmpty()) {
                    if (downloadingTasks.isEmpty()) {
                        switchToFinished()
                    }
                } else {
                    handleNextDownload()
                }
            } else if (modelInitState.value == ModelInitState.Pausing) {
                if (downloadingTasks.isEmpty()) {
                    switchToPaused()
                }
            } else if (modelInitState.value == ModelInitState.Clearing) {
                if (downloadingTasks.isEmpty()) {
                    clear()
                }
            } else if (modelInitState.value == ModelInitState.Deleting) {
                if (downloadingTasks.isEmpty()) {
                    delete()
                }
            }
        }

        private fun clear() {
            val files = modelDirFile.listFiles { dir, name ->
                !(dir == modelDirFile && name == ModelConfigFilename)
            }
            require(files != null)
            for (file in files) {
                file.deleteRecursively()
                require(!file.exists())
            }
            val modelConfigFile = File(modelDirFile, ModelConfigFilename)
            require(modelConfigFile.exists())
            switchToIndexing()
        }

        private fun delete() {
            modelDirFile.deleteRecursively()
            require(!modelDirFile.exists())
            requestDeleteModel(modelConfig.modelId)
        }

        private fun switchToPausing() {
            modelInitState.value = ModelInitState.Pausing
        }

        private fun switchToPaused() {
            modelInitState.value = ModelInitState.Paused
        }


        private fun switchToFinished() {
            modelInitState.value = ModelInitState.Finished
        }

        fun startChat() {
            chatState.requestReloadChat(
                modelConfig,
                modelDirFile.absolutePath,
            )
        }

    }

    inner class ChatState {
        val messages = emptyList<MessageData>().toMutableStateList()
        val report = mutableStateOf("")
        val modelName = mutableStateOf("")
        private var modelChatState = mutableStateOf(ModelChatState.Ready)
            @Synchronized get
            @Synchronized set
        private val engine = MLCEngine()
        private var historyMessages = mutableListOf<ChatCompletionMessage>()
        private var modelLib = ""
        private var modelPath = ""
        private val executorService = Executors.newSingleThreadExecutor()
        private val viewModelScope = CoroutineScope(Dispatchers.Main + Job())
        private fun mainResetChat() {
            executorService.submit {
                callBackend { engine.reset() }
                historyMessages = mutableListOf<ChatCompletionMessage>()
                viewModelScope.launch {
                    clearHistory()
                    switchToReady()
                }
            }
        }

        private fun clearHistory() {
            messages.clear()
            report.value = ""
            historyMessages.clear()
        }


        private fun switchToResetting() {
            modelChatState.value = ModelChatState.Resetting
        }

        private fun switchToGenerating() {
            modelChatState.value = ModelChatState.Generating
        }

        private fun switchToReloading() {
            modelChatState.value = ModelChatState.Reloading
        }

        private fun switchToReady() {
            modelChatState.value = ModelChatState.Ready
        }

        private fun switchToFailed() {
            modelChatState.value = ModelChatState.Falied
        }

        private fun callBackend(callback: () -> Unit): Boolean {
            try {
                callback()
            } catch (e: Exception) {
                viewModelScope.launch {
                    val stackTrace = e.stackTraceToString()
                    val errorMessage = e.localizedMessage
                    appendMessage(
                        MessageRole.Assistant,
                        "MLCChat failed\n\nStack trace:\n$stackTrace\n\nError message:\n$errorMessage"
                    )
                    switchToFailed()
                }
                return false
            }
            return true
        }

        fun requestResetChat() {
            require(interruptable())
            interruptChat(
                prologue = {
                    switchToResetting()
                },
                epilogue = {
                    mainResetChat()
                }
            )
        }

        private fun interruptChat(prologue: () -> Unit, epilogue: () -> Unit) {
            // prologue runs before interruption
            // epilogue runs after interruption
            require(interruptable())
            if (modelChatState.value == ModelChatState.Ready) {
                prologue()
                epilogue()
            } else if (modelChatState.value == ModelChatState.Generating) {
                prologue()
                executorService.submit {
                    viewModelScope.launch { epilogue() }
                }
            } else {
                require(false)
            }
        }

        fun requestTerminateChat(callback: () -> Unit) {
            require(interruptable())
            interruptChat(
                prologue = {
                    switchToTerminating()
                },
                epilogue = {
                    mainTerminateChat(callback)
                }
            )
        }

        private fun mainTerminateChat(callback: () -> Unit) {
            executorService.submit {
                callBackend { engine.unload() }
                viewModelScope.launch {
                    clearHistory()
                    switchToReady()
                    callback()
                }
            }
        }

        private fun switchToTerminating() {
            modelChatState.value = ModelChatState.Terminating
        }


        fun requestReloadChat(modelConfig: ModelConfig, modelPath: String) {

            if (this.modelName.value == modelConfig.modelId && this.modelLib == modelConfig.modelLib && this.modelPath == modelPath) {
                return
            }
            require(interruptable())
            interruptChat(
                prologue = {
                    switchToReloading()
                },
                epilogue = {
                    mainReloadChat(modelConfig, modelPath)
                }
            )
        }

        private fun mainReloadChat(modelConfig: ModelConfig, modelPath: String) {
            clearHistory()
            this.modelName.value = modelConfig.modelId
            this.modelLib = modelConfig.modelLib
            this.modelPath = modelPath

            executorService.submit {
                /** Update 3/27/2025 **/
                mlcEvents.put("modelloading.start", (System.currentTimeMillis()).toString())
                val modelLoadStart = System.currentTimeMillis()
                Log.d("MLC_EVENT", ">>> Model loading started at $modelLoadStart ms")
                /** Update 3/27/2025 **/

                viewModelScope.launch {
                    Toast.makeText(application, "Initialize...", Toast.LENGTH_SHORT).show()
                }
                if (!callBackend {
                        engine.unload()
                        engine.reload(modelPath, modelConfig.modelLib)
                    }) return@submit

                /** Update 3/27/2025 **/
                mlcEvents.put("modelloading.end", (System.currentTimeMillis()).toString())
                val modelLoadEnd = System.currentTimeMillis()
                val modelLoadTime = modelLoadEnd - modelLoadStart
                Log.d("MLC_EVENT", ">>> Model loading finished at $modelLoadEnd ms")
                Log.d("MLC_EVENT", ">>> Total model load time: $modelLoadTime ms")
                /** Update 3/27/2025 **/

                viewModelScope.launch {
                    Toast.makeText(application, "Ready to chat", Toast.LENGTH_SHORT).show()
                    switchToReady()
                    // === Load prompts and simulate interactions ===
                    val conversations = loadPromptsFromAssets(application)
                    simulateConversations(conversations)
                }
            }
        }

        /** Function to handle sending a new prompt to the LLM
         * prompt: String is the user input **/
        fun requestGenerate(prompt: String) {
            require(chatable()) // Ensures the model is in a "ready" state
            switchToGenerating() // Switches internal state to Generating
            appendMessage(MessageRole.User, prompt)
            appendMessage(MessageRole.Assistant, "")//Prepares a placeholder (empty string) for the assistant's streaming response

            executorService.submit { //Everything inside happens asynchronously
                /** Update 3/28/2025 **/
                mlcEvents.put("prefill." + responseId + ".start", (System.currentTimeMillis()).toString())
                /** Update 3/28/2025 **/

                /** Update 3/26/2025 **/
                val prefillStart = System.currentTimeMillis()
                Log.d("MLC_EVENT", ">>> Prefill started at $prefillStart ms")
                /** Update 3/26/2025 **/


                if (android.os.Trace.isEnabled()) {          // ← parentheses around the condition
                    Log.d("ATrace", ">>> ATrace is enabled")
                } else {
                    Log.d("ATrace", ">>> ATrace is disabled")
                }

//                android.os.Trace.beginSection("mlc_prefill")

                historyMessages.add(ChatCompletionMessage( //Adds the current prompt to the model’s internal chat history (historyMessages),
                    // so the model knows the full conversation context.
                    role = OpenAIProtocol.ChatCompletionRole.user,
                    content = prompt
                ))

                viewModelScope.launch { //switch to the main coroutine scope to collect streaming results from the model.
                    /** Update 5/20/2025 **/
                    val responses = engine.chat.completions.create(
                        messages        = historyMessages,
                        max_tokens      = 64,          // max-new-tokens
                        stop            = emptyList(),  // <- ignore stop-strings as well
//                        stop_token_ids  = intArrayOf(), // <- ignore EOS tokens
                        seed = 12345,
                        temperature = 0.0f,
                        top_p = 1.0f,
                        stream_options   = OpenAIProtocol.StreamOptions(include_usage = true)
                    )

//                    val responses = engine.chat.completions.create( //This starts a streaming chat session with the LLM, yielding a flow of response chunks.
//                        messages = historyMessages,
//                        stream_options = OpenAIProtocol.StreamOptions(include_usage = true) //makes it return token usage & stats as well
//                    )
                    /** Update 5/20/2025 **/

                    var finishReasonLength = false // Set end generation triggered by "length" → Hit context limit (truncation)
                    var streamingText = ""
                    /** Update 3/26/2025 **/
                    var prefillLogged = false
                    var prefillDone: Long = 0L
                    /** Update 3/26/2025 **/

                    for (res in responses) {
                        /** Update 3/26/2025 **/
//                        if (!prefillLogged) {
//                            /** Update 3/28/2025 **/
//                            mlcEvents.put("prefill." + responseId + ".end", (System.currentTimeMillis()).toString())
//                            /** Update 3/28/2025 **/
//
//                            prefillDone = System.currentTimeMillis()
//                            Log.d("MLC_EVENT", ">>> Prefill complete at ${System.currentTimeMillis()} ms")
//                            Log.d("MLC_EVENT", ">>> Time from prompt to prefill: ${prefillDone - prefillStart} ms")
//                            prefillLogged = true
////                            android.os.Trace.endSection()
//                        }
                        /** Update 3/26/2025 **/

                        if (!callBackend {
                            for (choice in res.choices) {
                                choice.delta.content?.let { content ->
                                    streamingText += content.asText()
                                }
                                // checks if the generation ended due to "stop" -> Finished normally or "length" -> Hit context limit (truncation)
                                choice.finish_reason?.let { finishReason ->
                                    if (finishReason == "length") {
                                        finishReasonLength = true
                                    }
                                }
                            }
                            updateMessage(MessageRole.Assistant, streamingText) //pushes the latest assistant response into the UI every time there's new content from the LLM. res.usage comes from the MLC which returns a List<ChatCompletionChunk> or something similar
                            res.usage?.let { finalUsage ->
                                report.value = finalUsage.extra?.asTextLabel() ?: "" //metrics to be diplayed in ChatView.kt

                                /** Update 3/26/2025 **/
                                val promptTokens = finalUsage.prompt_tokens ?: -1
                                val completionTokens = finalUsage.completion_tokens ?: -1
                                val totalTokens = finalUsage.total_tokens ?: -1
                                val extra = finalUsage.extra
                                val prefillSpeed = extra?.prefill_tokens_per_s ?: -1.0
                                val decodeSpeed = extra?.decode_tokens_per_s ?: -1.0
//                                val prefillTokens = extra?.num_prefill_tokens ?: -1
                                Log.d("MLC_Profile", "Response#: $responseId, Prompt: '$prompt'\n" + "Response: '$streamingText'\n"+
                                        "prompt_tokens=$promptTokens, completion_tokens=$completionTokens, total_tokens=$totalTokens\n" +
                                        "prefill_tokens_per_s=$prefillSpeed, decode_tokens_per_s=$decodeSpeed")
                            }
                            if (finishReasonLength) {
                                streamingText += " [output truncated due to context length limit...]"
                                updateMessage(MessageRole.Assistant, streamingText)
                            }
                        });
                    }
                    if (streamingText.isNotEmpty()) {
                        historyMessages.add(ChatCompletionMessage(
                            role = OpenAIProtocol.ChatCompletionRole.assistant,
                            content = streamingText
                        ))
                        streamingText = ""
                    } else {
                        if (historyMessages.isNotEmpty()) {
                            historyMessages.removeAt(historyMessages.size - 1)
                        }
                    }

                    if (modelChatState.value == ModelChatState.Generating) {
                        /** Update 3/28/2025 **/
//                        val fileName = "${modelName.value}-${timestamp}.csv"
//                        val dir = File(
//                            Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOCUMENTS).toString() +
//                                    File.separator + "event_profile")
//                        val file = File(dir, fileName)
//                        if (!file.parentFile.exists()) {
//                            file.parentFile.mkdirs()
//                        }

//                        saveMLCEventsToCSV(file)
                        Log.d("MLC_EVENT", ">>> Sleeping for 5 seconds after each response")
                        mlcEvents.put("sleep." + responseId + ".start", (System.currentTimeMillis()).toString())
                        delay(5000)  // suspends the coroutine for 5 seconds
                        mlcEvents.put("sleep." + responseId + ".end", (System.currentTimeMillis()).toString())
                        responseId++
                        switchToReady()
                        Log.d("MLC_EVENT", ">>> Model state switched to READY")
                        /** Update 3/28/2025 **/
                    }
                }
            }
        }

        /** Update 3/24/2025 **/
        fun simulateConversations(conversations: List<List<String>>) {
            executorService.submit {
                viewModelScope.launch {
                    for (conversation in conversations) {
                        for (prompt in conversation) {
                            if (!chatable()) break
                            requestGenerate(prompt)
                            while (!chatable()) {
//                                delay(1) //Suspends the coroutine for 100 ms each pass.
                                yield()            // keep CPU usage near-zero, latency minimal
                            }
                        }
                        clearHistory()
                        Log.d("MLC_EVENT", ">>> Clear history after each conversation")
                    }
                    resetMLCEvents()
                }
            }
        }
        /** Update 3/24/2025 **/

        /** Update 3/28/2025 **/
        private fun resetMLCEvents() {
            mlcEvents.clear()
            responseId = 0
        }

//        private fun saveMLCEventsToCSV(file: File) {
//            try {
//                FileWriter(file).use { writer ->
//                    for ((key, value) in mlcEvents) {
//                        writer.append("$key,$value\n")
//                    }
//                }
//            } catch (e: IOException) {
//                e.printStackTrace()
//            }
//        }

//        private fun appendProfileLogToJsonFile(file: File, newEntry: ProfileLogEntry) {
//            val gson = GsonBuilder()
//                .setPrettyPrinting()
//                .disableHtmlEscaping()
//                .create()
//
//            // Read existing entries if file exists
//            val existingEntries: MutableList<ProfileLogEntry> = if (file.exists()) {
//                try {
//                    val content = file.readText()
//                    if (content.isNotBlank()) {
//                        gson.fromJson(content, Array<ProfileLogEntry>::class.java).toMutableList()
//                    } else {
//                        mutableListOf()
//                    }
//                } catch (e: Exception) {
//                    e.printStackTrace()
//                    mutableListOf()
//                }
//            } else {
//                mutableListOf()
//            }
//
//            // Add the new entry
//            existingEntries.add(newEntry)
//
//            // Save back to file with pretty printed and unescaped JSON
//            try {
//                FileWriter(file, false).use { writer -> // Overwrite with new list
//                    val jsonString = gson.toJson(existingEntries)
//                    writer.write(jsonString + "\n")
//                }
//            } catch (e: IOException) {
//                e.printStackTrace()
//                Log.e("MLC_Profile", "Failed to save profile log.")
//            }
//        }

//        private fun appendProfileLogToJsonFile(file: File, newEntry: ProfileLogEntry) {
//            val gson = Gson()
//            // Read existing entries if file exists
//            val existingEntries: MutableList<ProfileLogEntry> = if (file.exists()) {
//                try {
//                    val content = file.readText()
//                    if (content.isNotBlank()) {
//                        gson.fromJson(content, Array<ProfileLogEntry>::class.java).toMutableList()
//                    } else mutableListOf()
//                } catch (e: Exception) {
//                    e.printStackTrace()
//                    mutableListOf()
//                }
//            } else mutableListOf()
//
//            // Add the new entry
//            existingEntries.add(newEntry)
//
//            // Save back to file
//            try {
//                FileWriter(file, false).use { writer -> // Overwrite with new list
//                    val jsonString = gson.toJson(existingEntries)
//                    writer.write(jsonString + "\n")
//                }
//            } catch (e: IOException) {
//                e.printStackTrace()
//                Log.e("MLC_Profile", "Failed to save profile log.")
//            }
//        }

        /** Update 3/28/2025 **/

        private fun appendMessage(role: MessageRole, text: String) {
            messages.add(MessageData(role, text))
        }


        private fun updateMessage(role: MessageRole, text: String) {
            messages[messages.size - 1] = MessageData(role, text)
        }

        fun chatable(): Boolean {
            return modelChatState.value == ModelChatState.Ready
        }

        fun interruptable(): Boolean {
            return modelChatState.value == ModelChatState.Ready
                    || modelChatState.value == ModelChatState.Generating
                    || modelChatState.value == ModelChatState.Falied
        }
    }
}

enum class ModelInitState {
    Initializing,
    Indexing,
    Paused,
    Downloading,
    Pausing,
    Clearing,
    Deleting,
    Finished
}

enum class ModelChatState {
    Generating,
    Resetting,
    Reloading,
    Terminating,
    Ready,
    Falied
}

enum class MessageRole {
    Assistant,
    User
}

data class DownloadTask(val url: URL, val file: File)

data class MessageData(val role: MessageRole, val text: String, val id: UUID = UUID.randomUUID())

data class AppConfig(
    @SerializedName("model_libs") var modelLibs: MutableList<String>,
    @SerializedName("model_list") val modelList: MutableList<ModelRecord>,
)

data class ModelRecord(
    @SerializedName("model_url") val modelUrl: String,
    @SerializedName("model_id") val modelId: String,
    @SerializedName("estimated_vram_bytes") val estimatedVramBytes: Long?,
    @SerializedName("model_lib") val modelLib: String
)

data class ModelConfig(
    @SerializedName("model_lib") var modelLib: String,
    @SerializedName("model_id") var modelId: String,
    @SerializedName("estimated_vram_bytes") var estimatedVramBytes: Long?,
    @SerializedName("tokenizer_files") val tokenizerFiles: List<String>,
    @SerializedName("context_window_size") val contextWindowSize: Int,
    @SerializedName("prefill_chunk_size") val prefillChunkSize: Int,
)

data class ParamsRecord(
    @SerializedName("dataPath") val dataPath: String
)

data class ParamsConfig(
    @SerializedName("records") val paramsRecords: List<ParamsRecord>
)
