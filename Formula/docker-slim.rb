class DockerSlim < Formula
  desc "Minify and secure Docker images"
  homepage "https://slimtoolkit.org/"
  url "https://github.com/slimtoolkit/slim/archive/refs/tags/1.40.3.tar.gz"
  sha256 "7b72b423ba3d031cbd5113ad35bf2ef1e8f2088f7dbb37e348ca5cd8292af1bc"
  license "Apache-2.0"

  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ventura:  "5ab92b6c78f4dc8179b3575dae9158170872f81281bb56fd817a827506921cd5"
    sha256 cellar: :any_skip_relocation, arm64_monterey: "5ab92b6c78f4dc8179b3575dae9158170872f81281bb56fd817a827506921cd5"
    sha256 cellar: :any_skip_relocation, arm64_big_sur:  "5ab92b6c78f4dc8179b3575dae9158170872f81281bb56fd817a827506921cd5"
    sha256 cellar: :any_skip_relocation, ventura:        "5faa29ecabe2a483b46b2228d426c698b0040c8a28ebc180e6a0bc4f7b877afd"
    sha256 cellar: :any_skip_relocation, monterey:       "5faa29ecabe2a483b46b2228d426c698b0040c8a28ebc180e6a0bc4f7b877afd"
    sha256 cellar: :any_skip_relocation, big_sur:        "5faa29ecabe2a483b46b2228d426c698b0040c8a28ebc180e6a0bc4f7b877afd"
    sha256 cellar: :any_skip_relocation, x86_64_linux:   "5092616250c8c69fe5e0786c16033773c9acaa03858a82aaf807684312cc833a"
  end

  depends_on "go" => :build

  skip_clean "bin/slim-sensor"

  def install
    system "go", "generate", "./pkg/appbom"
    ldflags = "-s -w -X github.com/docker-slim/docker-slim/pkg/version.appVersionTag=#{version}"
    system "go", "build",
                 *std_go_args(output: bin/"slim", ldflags: ldflags),
                 "./cmd/slim"

    # slim-sensor is a Linux binary that is used within Docker
    # containers rather than directly on the macOS host.
    ENV["GOOS"] = "linux"
    system "go", "build",
                 *std_go_args(output: bin/"slim-sensor", ldflags: ldflags),
                 "./cmd/slim-sensor"
    (bin/"slim-sensor").chmod 0555
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/slim --version")
    system "test", "-x", bin/"slim-sensor"

    (testpath/"Dockerfile").write <<~EOS
      FROM alpine
      RUN apk add --no-cache curl
    EOS

    output = shell_output("#{bin}/slim lint #{testpath}/Dockerfile")
    assert_match "id='ID.10001' name='Missing .dockerignore'", output
    assert_match "id='ID.20006' name='Stage from latest tag'", output
  end
end
