Pod::Spec.new do |s|

  s.name         = "zxybpensdk"
  s.summary      = "A short description of zxybpensdk."

  s.homepage     = "https://github.com/Coder-YS/ZXYBPenSDK.git"

  s.license      = "MIT"

  s.author             = { "[HEJJY]" => "326629321@qq.com" }
  s.version = "1.0.2"
  s.platform     = :ios
  s.platform     = :ios, "9.0"

  s.source       = { :git => "https://github.com/Coder-YS/ZXYBPenSDK.git", :tag => "#{s.version}" }

 s.source_files  = "zxybpensdk.framework/Headers/*.h"
  # s.exclude_files = "Classes/Exclude"

  s.public_header_files = "zxybpensdk.framework/Headers/*.h"

  s.vendored_frameworks = 'zxybpensdk.framework'

  s.requires_arc = true
end