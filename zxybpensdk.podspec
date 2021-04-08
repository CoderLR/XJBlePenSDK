Pod::Spec.new do |s|
    s.name         = 'zxybpensdk'
    s.version      = '1.0.3'
    s.summary      = 'A short description of zxybpensdk.'
    s.homepage     = 'https://github.com/Coder-YS/ZXYBPenSDK'
    s.license      = 'MIT'
    s.authors      = {'HEJJY' => '326629321@qq.com'}
    s.platform     = :ios, '9.0'
    s.source       = {:git => 'https://github.com/Coder-YS/ZXYBPenSDK.git', :tag => s.version}
    s.source_files = 'zxybpensdk/zxybpensdk.framework/Headers/*.h'
    s.public_header_files = 'zxybpensdk/zxybpensdk.framework/Headers/*.h'
    s.vendored_frameworks = 'zxybpensdk/zxybpensdk.framework'
    s.requires_arc = true
end