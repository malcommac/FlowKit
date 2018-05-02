Pod::Spec.new do |s|
  s.name         = "FlowKitManager"
  s.version      = "0.5.3"
  s.summary      = "Declarative and type-safe UITableView & UICollectionView; a new way to work with tables and collections"
  s.description  = <<-DESC
    Efficient, declarative and type-safe approach to create and manage UITableView and UICollectionView with built-in animation support.
  DESC
  s.homepage     = "https://github.com/malcommac/FlowKit"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author             = { "Daniele Margutti" => "me@danielemargutti.com" }
  s.social_media_url   = "https://twitter.com/danielemargutti"
  s.ios.deployment_target = "9.0"
  s.source       = { :git => "https://github.com/malcommac/FlowKit.git", :tag => s.version.to_s }
  s.source_files  = "Sources/**/*"
  s.frameworks  = "Foundation"
  s.swift_version = "4.0"
end
