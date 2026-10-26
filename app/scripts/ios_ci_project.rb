require 'xcodeproj'
require 'json'

signing = JSON.parse(File.read(File.join(ENV.fetch('RUNNER_TEMP'), 'dropit-signing', 'profile.json')))
project = Xcodeproj::Project.open('ios/Runner.xcodeproj')
runner = project.targets.find { |target| target.name == 'Runner' }
raise 'Missing Runner target' unless runner
runner.build_configurations.each do |config|
  next unless %w[Release Profile].include?(config.name)
  config.build_settings['CODE_SIGN_STYLE'] = 'Manual'
  config.build_settings['CODE_SIGN_IDENTITY'] = 'Apple Distribution'
  config.build_settings['DEVELOPMENT_TEAM'] = signing.fetch('team')
  config.build_settings['PROVISIONING_PROFILE_SPECIFIER'] = signing.fetch('name')
  config.build_settings['APS_ENVIRONMENT'] = 'production'
end
project.save
