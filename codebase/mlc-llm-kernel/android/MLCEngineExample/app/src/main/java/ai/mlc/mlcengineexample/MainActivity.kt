package ai.mlc.mlcengineexample

import ai.mlc.mlcengineexample.ui.theme.MLCEngineExampleTheme
import ai.mlc.mlcllm.MLCEngine
import ai.mlc.mlcllm.OpenAIProtocol
import ai.mlc.mlcllm.OpenAIProtocol.*
import android.annotation.SuppressLint
import android.os.Bundle
import android.util.Log
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Modifier
import kotlinx.coroutines.GlobalScope
import kotlinx.coroutines.channels.ReceiveChannel
import kotlinx.coroutines.launch
import java.io.File


class MainActivity : ComponentActivity() {
    @SuppressLint("CoroutineCreationDuringComposition")
    @ExperimentalMaterial3Api
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val modelName = "gemma-2b-q4f16_1-MLC"
        var modelPath = File(application.getExternalFilesDir(""), modelName).toString()
        Log.i("MLC", "model path: $modelPath")
        // need to be changed to the custom system lib prefix used while compiling the model
        val modelLib = "gemma_q4f16_1_0619fb425cb5c22ecfb27b655043d1ff"
        Log.i("MLC", "engine loaded")

        setContent {
            val responseText = remember { mutableStateOf("") }
            val coroutineScope = rememberCoroutineScope()

            val engine = MLCEngine()
            engine.unload()
//            loading model
            Log.i("MLC", "start model loading")
            engine.reload(modelPath, modelLib)
            Log.i("MLC", "model loaded")

//            Start text generation using coroutines
            coroutineScope.launch {
                var channel = engine.chat.completions.create(
                    messages = listOf(
                        ChatCompletionMessage(
                            role = OpenAIProtocol.ChatCompletionRole.user,
                            content = "What is the meaning of life?"
                        )
                    ),
                    stream_options = OpenAIProtocol.StreamOptions(include_usage = true)
                )

//                Handle streaming responses
                for (response in channel) {
                    val finalusage = response.usage
                    if (finalusage != null) {
                        responseText.value += "\n" + (finalusage.extra?.asTextLabel() ?: "")
                        Log.i("MLC", "finalusage: $finalusage")
                        /** Example: CompletionUsage(prompt_tokens=17, completion_tokens=349, total_tokens=366,
                         * extra=CompletionUsageExtra(prefill_tokens_per_s=0.45228595, decode_tokens_per_s=6.7765627,
                         * num_prefill_tokens=null))**/
                    } else {
                        if (response.choices.size > 0) {
                            responseText.value += response.choices[0].delta.content?.asText()
                                .orEmpty()
                        }
                    }

                }
            }

//            Display the generated text in UI
            Surface(
                modifier = Modifier
                    .fillMaxSize()
            ) {
//                MLCEngineExampleTheme {
//                    Text(text = responseText.value)
//                }
            }
        }
    }
}
