# How to build LM-Meter locally
## A. Prerequisites

### a. Install [Rust](https://www.rust-lang.org/tools/install)

`LM_Meter` relies on **Rust 1.75.0** to cross-compile HuggingFace tokenizers for Android. Install rustup by

```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
# Install and pin Rust 1.75.0
rustup toolchain install 1.75.0
rustup default 1.75.0
rustup target add --toolchain 1.75.0 aarch64-linux-android
rustup override set 1.75.0
```
Make sure `rustc`, `cargo`, and `rustup` are available in your `$PATH` by updating your `~/.zshrc`(MacOS), `~/.bashrc` (Linux). Open your shell configuration file `~/.zshrc` or `~/.bashrc` (depending on your operating system) by 
```bash
open -a TextEdit ~/.zshrc # MacOS
#OR edit directly in terminal
nano ~/.zshrc # MacOS
nano ~/.bashrc # Linux
```
Then append the following snippet to the end of your `~/.zshrc` or `~/.bashrc`. This ensures that binaries installed by `rustup` take precedence over any Rust versions bundled by Conda or system packages.
```bash
source "$HOME/.cargo/env"
# Ensure Rust from rustup wins over Conda Rust
if [ -f "$HOME/.cargo/env" ]; then
  . "$HOME/.cargo/env"
else
  export PATH="$HOME/.cargo/bin:$PATH"
fi
export RUSTUP_TOOLCHAIN=1.75.0
```
After saving the file, reload it so the changes take effect.
```bash
# MacOS
source ~/.zshrc 
# Linux
source ~/.bashrc 
```
Run the following commands to confirm everything is set up correctly:
```bash
rustc --version # should report rustc 1.75.0
cargo --version # should report cargo 1.75.0
rustup show active-toolchain
```

### b. Install Java
`LM_Meter` requires **Java 17**. Here we provide an example of installing Java on MacOS.
```bash
brew install --cask temurin@17
```
Verify the installation:
```bash
/usr/libexec/java_home -V
# Should see Matching Java Virtual Machines (1): 17.0.16 (arm64) "Eclipse Adoptium" - "OpenJDK 17.0.16" /Library/Java/JavaVirtualMachines/temurin-17.jdk ...
```
Point JAVA_HOME to JDK 17 by appending the following snippet your `~/.zshrc` or `~/.bashrc`.
```bash
export JAVA_HOME="$(/usr/libexec/java_home -v 17)"
export PATH="$JAVA_HOME/bin:$PATH"
```
Remember to reload the shell.
```bash
source ~/.zshrc
```
Verify
```bash
echo $JAVA_HOME
$JAVA_HOME/bin/java -version
java -version
# All three should now report 17.0.16.
```

### c. Install Android Studio with NDK and CMake
To install `NDK` and `CMake`, on Android Studio click `Tools → SDK Manager → SDK Tools`. The current Android APK is built with `NDK 27.0.11718014`. Once installing the SDK, NDK, Java properly, append the following snippet to your `~/.zshrc` or `~/.bashrc`.
```bash
export PATH=$PATH:$HOME/Library/Android/sdk/platform-tools
export ANDROID_NDK=$HOME/Library/Android/sdk/ndk/27.0.11718014
export TVM_NDK_CC=$ANDROID_NDK/toolchains/llvm/prebuilt/darwin-x86_64/bin/aarch64-linux-android24-clang
```
Remember to reload the shell.
```bash
source ~/.zshrc
```

## B. Conda Environments & Clone LM-Meter
LM-Meter requires carefully configured environments to ensure reproducibility across different profiling modes (kernel-level, phase-level). We provide explicit environment files for MacOS (Apple Silicon) and will extend support to Linux and Intel MacOS soon.
### a. Clone LM-Meter
Clone the repository along with its submodules:
```bash
git clone --recurse-submodules git@github.com:amai-gsu/lm-Meter-Private-Experiment.git NAME
cd NAME
```
> ⚡ **Note**: Replace `NAME` with your desired folder name. The `--recurse-submodules` flag is required since LM-Meter depends on submodules like Perfetto.
### b. Conda-forge 
Add conda-forge channel to your global conda configuration.
```bash
conda config --add channels conda-forge
conda config --set channel_priority flexible
```
### c. Create Conda Environments
Please use our provided explicit environment files under `environment/` to reproduce the exact dependencies.
If your host machine is MacOS with M chipsets:
```bash
cd environment/
# Kernel-level profiling
conda create -n lm-meter-kernel --file conda-osx-arm64-explicit-kernel.txt
# Phase-level profiling
conda create -n lm-meter-infer --file conda-osx-arm64-explicit-infer.txt
# Melting point profiling (our reproduced version)
conda create -n melt-reproduce --file conda-osx-arm64-explicit-melt.txt
```
Then, Activate the environment that matches your research purpose.
```bash
conda activate lm-meter-kernel     # For kernel-level profiling
conda activate lm-meter-infer      # For phase-level profiling
conda activate melt-reproduce      # For melting point profiling
```
If your host machine is Linux or MacOS with Intel chipsets:
> ⏳ Coming soon — we are preparing explicit environment files for these platforms.

## C. Build LM-Meter from Source 
We created automated build scripts that streamline the compilation process and ensure reproducibility. All scripts are located in `\script` and `\script\build_util`. Before running any build, make sure to activate the corresponding conda environment.

To build LM-Meter with kernel-level profiling, you should activate the correct conda env (e.g., lm-meter-kernel) and run
```bash
cd /script
chmod +x ./build_all_e2e_plus_opencl_kernel.sh # First-time setup only 
./build_all_e2e_plus_opencl_kernel.sh
```
To build LM-Meter with phase-level profiling, you should activate the correct conda env (e.g., lm-meter-infer) and run
```bash
cd /script
chmod +x ./build_all_e2e_pure.sh # First-time setup only 
./build_all_e2e_pure.sh
```
To build our reproduced Melting Point profiler, you should activate the correct conda env (e.g., melt-reproduce) and run
```bash
cd /script
chmod +x ./build_all_e2e_melt_reproduce.sh # First-time setup only 
./build_all_e2e_melt_reproduce.sh
```
> ⚡ **Note**: Builds may take 20 minutes or more depending on your platform and hardware. Before running any build script, ensure that an Android device is connected to your host machine via `adb`, as the final build step will automatically deploy and install the generated APK on the device.