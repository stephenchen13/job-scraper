require "rubygems"
require "nokogiri"
require "open-uri"
require "sqlite3"

#jobs.rubynow.com

#check if database exists
#if doesn't exist, create schema
if !File.exist?("dice_jobs.db")
	@db = SQLite3::Database.new "dice_jobs.db"
	@db.execute <<-SQL
		CREATE TABLE jobs (
			id INTEGER PRIMARY KEY,
			title TEXT,
			job_link TEXT,
			location TEXT,
			posted_date TEXT,
			company_name TEXT,
			company_url TEXT,
			area_code TEXT,
			position_id TEXT,
			dice_id TEXT,
			description TEXT,
			pay_rate TEXT,
			skills TEXT,
			telecommute TEXT,
			travel_required TEXT
		);
	SQL
else
	@db = SQLite3::Database.open "dice_jobs.db"
end

DiceBaseUrl = "http://seeker.dice.com"
DiceUrl = "#{DiceBaseUrl}/jobsearch/servlet/JobSearch?WHERE=new+york&Ntx=mode+matchall&FRMT=0&QUICK=1&ZC_COUNTRY=0&SORTSPEC=0&N=0&Hf=0&Ntk=JobSearchRanking&op=300&LOCATION_OPTION=2&TAXTERM=0&RADIUS=64.37376&DAYSBACK=30&FREE_TEXT=ruby+rails&TRAVEL=0&NUM_PER_PAGE=150"
index = Nokogiri::HTML(open(DiceUrl))
jobs = index/".summary tbody tr"
jobs.each do |job|
	next if (job/"td.reminderRow").first

	job_title = (job/"td a").first.inner_text
	job_link = (job/"td a").first["href"].strip

	company_name = (job/"td a")[1].inner_text
	company_link = (job/"td a")[1]["href"].strip

	location = (job/"td")[2].inner_text
	date_posted = (job/"td")[3].inner_text.strip


	job_page = Nokogiri::HTML(open("#{DiceBaseUrl}#{job_link}"))

	area_code_selector = (job_page/"#jobOverview .pane dl dd")[1]
	if area_code_selector
		area_code = area_code_selector.inner_text.strip 
	else
		area_code_selector = (job_page/".job_overview dl dd")[5]
		area_code = area_code_selector.inner_text.strip if area_code_selector
	end

	telecommute_selector = (job_page/"#jobOverview .pane dl dd")[2]
	if telecommute_selector
		telecommute = telecommute_selector.inner_text.strip 
	else
		telecommute_selector = (job_page/".job_overview dl dd")[12]
		telecommute = telecommute_selector.inner_text.strip if telecommute_selector
	end
	
	travel_selector = (job_page/"#jobOverview .pane dl dd")[3]
	if travel_selector
		travel = travel_selector.inner_text.strip 
	else
		travel_selector = (job_page/".job_overview dl dd")[11]
		travel = travel_selector.inner_text.strip if travel_selector
	end

	skills_selector = (job_page/"#jobOverview .pane")[1]
	if skills_selector
		skills = (skills_selector/"dd").inner_text.strip 
	else
		skills_selector = (job_page/".job_overview dl dd")[2]
		skills = skills_selector.inner_text.strip if skills_selector
	end

	pay_rate_selector = (job_page/"#jobOverview .pane")[2]
	if pay_rate_selector
		pay_rate = (pay_rate_selector/"dd").first.inner_text.strip 
	else
		pay_rate_selector = (job_page/".job_overview dl dd")[7]
		pay_rate = pay_rate_selector.inner_text.strip if pay_rate_selector
	end

	position_id_selector = (job_page/"#jobOverview .pane")[3]
	if position_id_selector
		position_id = (position_id_selector/"dd")[1].inner_text.strip 
	else
		position_id_selector = (job_page/".job_overview dl dd")[9]
		position_id = position_id_selector.inner_text.strip if position_id_selector
	end

	dice_id_selector = (job_page/"#jobOverview .pane")[3]
	if dice_id_selector
		dice_id = (dice_id_selector/"dd")[2].inner_text.strip 
	else
		dice_id_selector = (job_page/".job_overview dl dd")[10]
		dice_id = dice_id_selector.inner_text.strip if dice_id_selector
	end

	description_selector = (job_page/"#detailDescription").first
	if description_selector
		description = description_selector.inner_text.strip 
	else
		description_selector = (job_page/".dc_content").first
		description = description_selector.inner_text.strip if description_selector
	end

	@db.execute("INSERT INTO jobs (title, job_link, location, posted_date, company_name, company_url, area_code, position_id, dice_id, description, pay_rate, skills, telecommute, travel_required)
		VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", [job_title, job_link, location, date_posted, company_name, company_link, area_code, position_id, dice_id, description, pay_rate, skills, telecommute, travel])
end
