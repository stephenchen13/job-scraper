require "rubygems"
require "nokogiri"
require "open-uri"
require "sqlite3"

#jobs.rubynow.com

#check if database exists
#if doesn't exist, create schema
if !File.exist?("jobs.db")
	@db = SQLite3::Database.new "jobs.db"
	@db.execute <<-SQL
		CREATE TABLE jobs (
			id INTEGER PRIMARY KEY,
			title TEXT,
			job_url TEXT,
			location TEXT,
			posted_date TEXT,
			company_name TEXT,
			company_site TEXT,
			description TEXT,
			type_of_position TEXT,
			work_hours TEXT,
			telecommute TEXT,
			email TEXT
		);
	SQL
else
	@db = SQLite3::Database.open "jobs.db"
end

RubyNow = "http://jobs.rubynow.com"
index = Nokogiri::HTML(open(RubyNow))
jobs = index/"ul.jobs li"
jobs.each do |job|
	date_posted = (job/"span.date").inner_text.strip
	job_title = (job/"h2 a").inner_text

	# scrape job link
	job_link = "#{RubyNow}#{(job/"h2 a").first["href"]}"
	job_page = Nokogiri::HTML(open(job_link))

	company_name_selector = (job_page/"h2#headline a").first
	company_name = company_name_selector.nil? ? (job_page/"h2#headline").inner_text.split(" at ")[1] : (job_page/"h2#headline a").inner_text

	company_url_selector = (job_page/"h2#headline a").first
	company_url = company_url_selector["href"] if company_url_selector

	location = (job_page/"h3#location").inner_text

	description = (job_page/"div#info").inner_text.strip

	description.match(/\s(\S+@\S+\.\S+?)\b/)
	company_email = $1

	description.match(/Type of position:\s*(.+)?[\b|W]/)
	position_type = $1

	description.match(/Work hours:\s*([^\sT]*)/)
	work_hours = $1

	description.match(/Telecommute:\s*(.+)?\b/)
	telecommute = $1

	@db.execute("INSERT INTO jobs (title, job_url, location, posted_date, company_name, company_site, description, type_of_position, work_hours, telecommute, email)
		VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", [job_title, job_link, location, date_posted, company_name, company_url, description, position_type, work_hours, telecommute, company_email])
end
