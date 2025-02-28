package 'nginx' do
  action :install
end

service 'nginx' do
  action [:enable, :start]
end

file '/var/www/html/index.html' do
  content '<h1>Hola, este servidor fue configurado con Chef!</h1>'
  mode '0644'
  owner 'www-data'
  group 'www-data'
end