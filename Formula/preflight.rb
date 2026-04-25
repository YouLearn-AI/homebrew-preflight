class Preflight < Formula
  desc "End-to-end QA testing for shipped Electron desktop apps"
  homepage "https://github.com/YouLearn-AI/preflight"
  url "https://github.com/YouLearn-AI/preflight.git",
      using: :git,
      tag:   "v0.1.0"
  license "MIT"
  version "0.1.0"

  depends_on "node"
  depends_on "pnpm"
  depends_on "ffmpeg"
  depends_on "tesseract" => :optional

  def install
    system "pnpm", "install", "--frozen-lockfile=false"
    system "pnpm", "build"
    libexec.install Dir["*"]
    (bin/"preflight").write <<~SH
      #!/usr/bin/env bash
      exec "#{Formula["node"].opt_bin}/node" "#{libexec}/packages/cli/dist/preflight.js" "$@"
    SH
    (bin/"preflight").chmod 0755
  end

  def caveats
    <<~EOS
      preflight needs THREE additional non-formula dependencies (no Homebrew tap):

        # 1. audiokit (audio injection CLI — node script via npm link)
        git clone https://github.com/YouLearn-AI/audiokit.git ~/Projects/audiokit
        cd ~/Projects/audiokit && npm install && npm link

        # 2. cua-driver (macOS Accessibility daemon — Mach-O bundle in /Applications)
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/trycua/cua/main/libs/cua-driver/scripts/install.sh)"

        # 3. blackhole-2ch (CoreAudio virtual mic device — Homebrew cask)
        brew install --cask blackhole-2ch

      After blackhole-2ch installs, you may need to log out + back in
      for CoreAudio to register the new virtual device.

      preflight needs macOS Privacy & Security permissions:
        Accessibility, Input Monitoring, Screen Recording, Microphone

      Run `preflight doctor --install-missing` to verify deps and
      open the Privacy panes for permission grants.

      After granting, fully QUIT and RELAUNCH your terminal —
      TCC grants attach at process launch.
    EOS
  end

  test do
    assert_match "preflight", shell_output("#{bin}/preflight --version")
  end
end
