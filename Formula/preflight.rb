class Preflight < Formula
  desc "End-to-end QA testing for shipped Electron desktop apps"
  homepage "https://github.com/YouLearn-AI/preflight"
  url "https://github.com/YouLearn-AI/preflight/archive/refs/tags/v0.1.0.tar.gz"
  sha256 "0000000000000000000000000000000000000000000000000000000000000000"
  license "MIT"
  version "0.1.0"

  depends_on "node"
  depends_on "pnpm"
  depends_on "youlearn-ai/audiokit/audiokit"
  depends_on "trycua/cua/cua-driver"
  depends_on "ffmpeg"
  depends_on "tesseract" => :optional
  depends_on cask: "blackhole-2ch"

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
