# service "apache2" do
#   action :nothing
# end

# %w{ apache2 php5.4.13 php-mysql }.each do |pkg|
#   package pkg do
#     notifies :restart, "service[apache2]"
#   end
# end

package "apache2" do
  action :install
end

apt_package "php5" do
  action :install
end

apt_package "php5-mysql" do
  action :install
end

file "/etc/httpd/conf.d/welcome.conf" do
  action :delete
end

service "apache2" do
  action [:enable, :start]
end

remote_file "/root/racksburg.tar.gz" do
  source "http://wordpress.org/latest.tar.gz"
end

execute "extract racksburg tar ball to html root" do
  command "tar -xzf /root/racksburg.tar.gz -C /var/www"
end

execute "change file permission" do
  command "chmod 755 -R /var/www/wordpress"
end

service "mysqld" do
  action :nothing
end

package "mysql-server" do
  action :install
  notifies :start, "service[mysqld]", :immediately
end

database_name = 'racksburg'
database_user = 'racker'
database_password = 'r@ck3rDB'

execute "setup database" do
  cmd = "mysql -u root -e \"CREATE DATABASE IF NOT EXISTS racksburg\""
  command cmd
  Chef::Log.info "Creating #{database_name} database..."
end

execute "create database user" do
  command "mysql -u root -e \"CREATE USER '#{database_user}'@'localhost' IDENTIFIED BY '#{database_password}'\""
  only_if do
    Chef::ShellOut.new('mysql -u racker -p#{database_password}').run_command.stdout.include?("Access denied")
  end
end

execute "Setup database user permission" do
  command "mysql -u root -e \"GRANT ALL PRIVILEGES ON #{database_name}.* TO '#{database_user}'@'localhost'; FLUSH PRIVILEGES\""
end
