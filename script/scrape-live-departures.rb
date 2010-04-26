wget = "/usr/local/bin/wget"
url = "http://www.livedepartureboards.co.uk/virgintrains/summary.aspx?T=DHM"
timestamp = Time.now.strftime("%Y%m%d%H%M")
directory="/Users/jamesmead/WebApps/trainplotter/#{timestamp}"

%x[#{wget} -e robots=off -r --directory-prefix=#{directory} --no-host-directories --wait=1 --random-wait --page-requisites --convert-links --html-extension #{url}]