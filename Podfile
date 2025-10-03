# Uncomment the next line to define a global platform for your project
platform :ios, '18.5'

# Sandbox問題とPackage Prebuild問題を回避するための設定
install! 'cocoapods', 
  :disable_input_output_paths => true,
  :preserve_pod_file_structure => true,
  :generate_multiple_pod_projects => false,
  :skip_pods_project_generation => false,
  :integrate_targets => true,
  :deterministic_uuids => true

target 'Micro Diary' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  pod 'Google-Mobile-Ads-SDK', :inhibit_warnings => true
  # Pods for Micro Diary

  target 'Micro DiaryTests' do
    inherit! :search_paths
    # Pods for testing
  end

  target 'Micro DiaryUITests' do
    # Pods for testing
  end

end
