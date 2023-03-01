if Rails.env == 'development'
  email_settings = YAML::load(File.open("#{Rails.root.to_s}/config/email_dev.yml"))
  ActionMailer::Base.smtp_settings = email_settings[Rails.env] unless email_settings[Rails.env].nil?
end

if Rails.env == 'production'
  email_settings = YAML::load(File.open("#{Rails.root.to_s}/config/email_prod.yml"))
  ActionMailer::Base.smtp_settings = email_settings[Rails.env] unless email_settings[Rails.env].nil?
end