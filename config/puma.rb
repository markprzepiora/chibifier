workers Integer(ENV['PUMA_WORKERS'] || 2)
threads Integer(ENV['MIN_THREADS']  || 1), Integer(ENV['MAX_THREADS'] || 32)

preload_app!

rackup      DefaultRackup
port        ENV['PORT']     || 9293
environment ENV['RACK_ENV'] || 'development'
