web: bundle exec rackup config.ru -p $PORT
resque: env TERM_CHILD=1 INTERVAL=0.05 bundle exec rake resque:work
