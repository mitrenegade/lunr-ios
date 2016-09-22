source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '9.0'
use_frameworks!

target 'Lunr' do

pod 'FBSDKCoreKit'
pod 'FBSDKLoginKit'
pod 'FBSDKShareKit'
pod 'Parse'
pod 'ParseFacebookUtilsV4'
pod 'Fabric'
pod 'Crashlytics'
       pod 'QuickBlox'
       pod 'Quickblox-WebRTC'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['ENABLE_BITCODE'] = 'NO'
    end
  end
end

