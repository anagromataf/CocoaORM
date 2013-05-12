Pod::Spec.new do |s|
  s.name         = "CocoaORM"
  s.version      = "0.0.3"
  s.summary      = "Object-relational mapping for Cocoa."
  s.homepage     = "https://github.com/anagromataf/CocoaORM"
  s.license      = { :type => 'BSD', :file => 'LICENSE.md' }  
  s.author       = { "Tobias Kräntzer" => "info@tobias-kraentzer.de" }
  s.source       = { :git => "https://github.com/anagromataf/CocoaORM.git", :tag => "0.0.3" }
  
  s.platform     = :osx, '10.8'
  s.source_files = 'CocoaORM/CocoaORM/*.{h,m}'
  
  s.requires_arc = true
  
  s.dependency 'FMDB', '~> 2.0'
end
