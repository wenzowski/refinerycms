# If we're using sqlite3 memory, refresh the database.
if Rails.application.config.database_configuration[ENV['RAILS_ENV']]['database'] == ':memory:'
  file = ENV['SCHEMA'] || Rails.root.join('db', 'schema.rb').to_s
  if File.exists?(file)
    load(file)
  else
    abort %{#{file} doesn't exist yet. Run `rake db:migrate` to create it then try again. If you do not intend to use a database, you should instead alter #{Rails.root}/config/application.rb to limit the frameworks that will be loaded}
  end
end