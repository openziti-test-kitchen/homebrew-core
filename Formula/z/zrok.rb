class Zrok < Formula
  desc "Geo-scale, next-generation sharing platform built on top of OpenZiti"
  homepage "https://zrok.io"
  url "https://github.com/openziti-test-kitchen/zrok-build-debugging/releases/download/v0.4.4912/source-v0.4.4912.tar.gz"
  sha256 "ea7ec194b397d6e01948ca91ef8c16f2ebea82ab3afbbedf0f637dd347fc0444"
  # The main license is Apache-2.0. ACKNOWLEDGEMENTS.md lists licenses for parts of code
  license all_of: ["Apache-2.0", "BSD-3-Clause", "MIT"]
  head "https://github.com/openziti/zrok.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_sequoia: "461c41aa835b4230ac14a4750091c6a36f9a13d4e34ed8ab3c6fb879726cd804"
    sha256 cellar: :any_skip_relocation, arm64_sonoma:  "15d01ee6fa23035816ac55f48a5d5453b50536647e34dd64bec013c2b0a8c90c"
    sha256 cellar: :any_skip_relocation, arm64_ventura: "87fcfe3e4bcc472d35d34f4933149462c3119948d16e81ec5ce20ca066de3ff4"
    sha256 cellar: :any_skip_relocation, sonoma:        "79a40907ddb8e6b65a9a3645f090e86279dddcd333701f0b07a8104f999fdb08"
    sha256 cellar: :any_skip_relocation, ventura:       "c44d1cc576808a715b7089a1a09d27c06bdb52d75fbc5b86c178cfd46e3000e1"
    sha256 cellar: :any_skip_relocation, x86_64_linux:  "afed55f742fe5dcbb8db3af7779d47b0a904825333644c0033f89f898f7d1d39"
  end

  depends_on "go" => :build
  depends_on "node" => :build

  def install
    cd buildpath/"ui" do
      system "npm", "install", *std_npm_args(prefix: false)
      system "npm", "run", "build"
    end

    ldflags = %W[
      -s -w
      -X github.com/openziti/zrok/build.Version=#{version}
      -X github.com/openziti/zrok/build.Hash=#{tap.user}
    ]
    system "go", "build", *std_go_args(ldflags:), "./cmd/zrok"
  end

  test do
    (testpath/"ctrl.yml").write <<~YAML
      v: 4
      maintenance:
        registration:
          expiration_timeout:           24h
          check_frequency:              1h
          batch_limit:                  500
        reset_password:
          expiration_timeout:           15m
          check_frequency:              15m
          batch_limit:                  500
    YAML

    version_output = shell_output("#{bin}/zrok version")
    assert_match(version.to_s, version_output)
    assert_match(/[[a-f0-9]{40}]/, version_output)

    status_output = shell_output("#{bin}/zrok controller validate #{testpath}/ctrl.yml 2>&1")
    assert_match("expiration_timeout = 24h0m0s", status_output)
  end
end
