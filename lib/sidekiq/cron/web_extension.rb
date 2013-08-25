module Sidekiq
  module Cron
    module WebExtension

      def self.registered(app)

        #very bad way of loading locales for cron jobs
        #should be rewritten
        app.helpers do

          alias_method :old_strings, :strings

          def strings
            #only on first load! 
            unless @strings
              #load all locales from Sidekiq
              old_strings

              Dir["#{File.join(File.expand_path("..", __FILE__), "locales")}/*.yml"].each do |file|
                YAML.load(File.open(file)).each do |locale, translations|
                  translations.each do |key, value|
                    @strings[locale][key] = value
                  end
                end
              end
            end
            @strings
          end
        end

        #index page of cron jobs
        app.get '/cron' do 
          view_path    = File.join(File.expand_path("..", __FILE__), "views")

          @cron_jobs = Sidekiq::Cron::Job.all

          render(:slim, File.read(File.join(view_path, "cron.slim")))
        end

        #enque cron job
        app.post '/cron/:name/enque' do |name|
          Sidekiq::Cron::Job.enque_by_name name
          redirect "#{root_path}cron"
        end

        #delete schedule
        app.post '/cron/:name/delete' do |name|
          Sidekiq::Cron::Job.remove name
          redirect "#{root_path}cron"
        end

      end
    end
  end
end