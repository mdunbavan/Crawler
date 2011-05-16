system("cls")
require 'rubygems'
require 'mechanize'
puts "mechanize loaded"

class Backup
  def initialize
    file = File.open($0).read
    Dir.mkdir("#{Dir.getwd}/backup") unless Dir.exist?("#{Dir.getwd}/backup")
    backup = File.new("#{Dir.getwd}/backup/backup_#{$0}_#{Time.now.to_s.gsub(":", "-")}.rb","w")
    backup.write(file)
    backup.close
  end
end
Backup.new

class Fixnum
  def count_forever
    value = self
    loop do
      yield value
      value += 1
    end
  end
end


class Download
  def initialize page
    @agent = Mechanize.new
    @page = @agent.get(page)
    @link = page
    @all_links = Array.new
    @all_links << @link
    Dir.mkdir("#{Dir.getwd}/log") unless Dir.exist?("#{Dir.getwd}/log")
    @log = File.new("#{Dir.getwd}/log/log_#{Time.now.to_s.gsub(":", "-")}.txt","w")
    @deep = 0
    @links_per_deep = Array.new
    @links_per_deep << Array.new
    @links_per_deep[0] << page
  end

  # crawl step bey step
  def craw(deep = -1, page = @link, show = true, crawl_deep = 0, &block) 
    @deep = -1

    #begin
      if deep > 0
        deep.times do |i|
          @links_per_deep[i].each do |link|
            begin
              crawl_one_deep(link, show, i+1, &block)
            rescue
              puts "#{i}::couldn't procress: #{link}" if show
              @log.puts "#{i}::couldn't procress: #{link}"
            end
          end
        end
      else
        0.count_forever do |i|
          @links_per_deep[i].each do |link|
            #begin
              crawl_one_deep(link, show, i+1, &block)
            #rescue
            #  puts "#{i+1}::couldn't procress: #{link}" if show
            #  @log.puts "#{i+1}::couldn't procress: #{link}"
            #end
          end
        end
      end
    #rescue Exception => e
      #puts e
    #ensure
      #puts "process finished"
    #end
  end
  
  def crawl_one_deep(page = @link, show = true, crawl_deep = 0, &block)
    @page = @agent.get(page)
    
    #thinks to do. download etc.
    yield page, @page if block_given?
    
    puts "#{crawl_deep}::#{page}" if show
    @log.puts "#{crawl_deep}::#{page}"
    
    @links_per_deep << Array.new
    @page.links.each do |link|
      #we ned the url
      link = link.href
      unless link.nil?
        
        
        unless link.include? "http://"
          if link.each_char.to_a.first == "/"
            link = "#{@link}#{link}"
          else
            link = "#{@link}/#{link}"
          end
        end
   
        if link.include? @link
          unless @all_links.include? link
            #each link shold onley once processed
            @all_links << link
            
            @links_per_deep[crawl_deep] << link
          end        
        end
      end
    end
  end
  
  def pictures(deep, page = @link, show = true)
    @all_images = Array.new
    
    #create download diary if not exist
    Dir.mkdir("#{Dir.getwd}/download") unless Dir.exist? "#{Dir.getwd}/download"
    Dir.mkdir("#{Dir.getwd}/download/pictures") unless Dir.exist? "#{Dir.getwd}/download/pictures"
    craw(deep, page = @link, show = true, crawl_deep = 0) do |link, page|
      page.image_urls.uniq.each do |url|
        unless @all_images.include? url.to_s
          @all_images << url.to_s
          img_name = "#{Dir.getwd}/download/pictures/#{url.to_s.split("/").last}"
          
          begin
            @agent.get(url).save_as(img_name)
            puts "saved: #{url.to_s}" if show
            @log.puts "saved: #{url.to_s}"
          rescue
            puts "failed to save: #{url.to_s}"
            @log.puts "failed to save: #{url.to_s}"
          end          
        end

      end
    end 
  end
end

if __FILE__ == $0
  download = Download.new "http://mechanize.rubyforge.org/mechanize/"
  print "puts deep: "
  download.pictures gets.to_i
end
