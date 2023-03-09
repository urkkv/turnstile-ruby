require 'bundler/setup'
require 'sinatra'
require 'turnstile'

# these will only work on localhost ... make your own at https://dash.cloudflare.com/
Turnstile.configure do |config|
  config.site_key  = '0x4AAAAAAAC1z764FTJAewGm'
  config.secret_key = '0x4AAAAAAAC1z_XZkOcOamwjRONkb-xoXMU'
end

include Turnstile::Adapters::ControllerMethods
include Turnstile::Adapters::ViewMethods

get '/' do
  <<-HTML
    <form action="/verify">
      #{turnstile_tags}
      <input type="submit"/>
    </form>
  HTML
end

get '/verify' do
  if verify_turnstile
    'YES!'
  else
    'NO!'
  end
end
