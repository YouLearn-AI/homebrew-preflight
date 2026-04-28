class Preflight < Formula
  desc "End-to-end QA testing for shipped Electron desktop apps"
  homepage "https://github.com/YouLearn-AI/preflight"
  url "https://github.com/YouLearn-AI/preflight.git",
      using:    :git,
      tag:      "v0.2.0",
      revision: "4a3586f1a7f54edb6070b67a907991ddf81cd7e6"
  license :cannot_represent

  depends_on "ffmpeg"
  depends_on "node"
  depends_on "pnpm"
  depends_on "python@3.12"
  depends_on "tesseract" => :optional

  def install
    # 1. Build the Node CLI from source.
    system "pnpm", "install", "--frozen-lockfile=false"
    system "pnpm", "build"
    libexec.install Dir["*"]

    # 2. Install the workflow brain's Python runtime deps into a flat dir
    #    via `pip install --target`. Skips venv creation (which ran ensurepip
    #    and failed in brew's install sandbox on Tier 2 configs); pip is
    #    already in the brewed python's site-packages so no bootstrap needed.
    #    websockets => CDP transport. pyyaml => workflow .md front-matter
    #    (the brain has a fallback parser, but yaml is more robust).
    #    openai => LLM tool-call dispatcher (skip-able if the user runs the
    #    brain via codex CLI; brain's import is guarded).
    python = Formula["python@3.12"].opt_bin/"python3.12"
    pylib = libexec/"pylib"
    pylib.mkpath
    system python, "-m", "pip", "install",
           "--target=#{pylib}",
           "--quiet",
           "--no-warn-script-location",
           "--disable-pip-version-check",
           "websockets", "pyyaml", "openai"

    # 3. Wrapper script: prepends the pylib dir to PYTHONPATH so the brain
    #    finds its deps; resolves through the Homebrew prefix symlink.
    (bin/"preflight").write <<~SH
      #!/usr/bin/env bash
      src="${BASH_SOURCE[0]}"
      while [ -L "$src" ]; do
        d="$(cd -P "$(dirname "$src")" && pwd)"
        src="$(readlink "$src")"
        case "$src" in /*) ;; *) src="$d/$src" ;; esac
      done
      export PYTHONPATH="#{pylib}${PYTHONPATH:+:$PYTHONPATH}"
      export PATH="#{Formula["python@3.12"].opt_bin}:$PATH"
      exec "#{Formula["node"].opt_bin}/node" "#{libexec}/packages/cli/dist/preflight.js" "$@"
    SH
    (bin/"preflight").chmod 0755
  end

  def caveats
    <<~EOS
      preflight needs three additional non-formula dependencies (no Homebrew
      tap exists for them):

        # 1. audiokit — public Node CLI for audio injection
        git clone https://github.com/YouLearn-AI/audiokit.git ~/.local/share/preflight/audiokit
        ( cd ~/.local/share/preflight/audiokit && npm install && npm link )

        # 2. cua-driver — public Swift Accessibility daemon
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/trycua/cua/main/libs/cua-driver/scripts/install.sh)"

        # 3. blackhole-2ch — CoreAudio virtual mic device (cask)
        brew install --cask blackhole-2ch

      After blackhole-2ch installs, you may need to log out + back in so
      CoreAudio picks up the new virtual device.

      macOS Privacy & Security panes — grant your terminal + CuaDriver.app:
        Accessibility · Input Monitoring · Screen Recording · Microphone

      After granting, fully QUIT and RELAUNCH your terminal — TCC grants
      attach at process launch, not when toggled.

      Required env:
        OPENAI_API_KEY  workflow brain (https://platform.openai.com/api-keys)
                        OR be logged into Codex CLI for --brain codex
        GEMINI_API_KEY  vision self-heal, recommended
                        (https://aistudio.google.com/apikey)

      First runs:
        preflight doctor                     # health check
        preflight workflow smoke             # ~30-60s liveness check
        preflight workflow jonah-customer-video --auto-loop 2
                                             # full customer walkthrough
        preflight workflow full-ui-matrix --auto-loop 2
                                             # exhaustive UI matrix

      Upgrade later with: preflight update    # auto-detects brew install
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/preflight --version")
  end
end
