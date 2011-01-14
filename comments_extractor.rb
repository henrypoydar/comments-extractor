#!/usr/bin/env ruby

# Quick and dirty hack to extract and  comments from Rails web app files: 
# .rb, .haml, .sass, .scss, .html, .js, .feature etc
#
# (c) Henry Poydar MIT/GPL

def print_usage
print <<USAGE

  usage: #{$0} /your/rails/app/path <extensions>
    where <extensions> are comma separated file extensions, e.g. html,js,rb 

USAGE
exit
end

print_usage if ARGV[0] == nil

class CommentExtractor

  def initialize(*args)
    @path = args[0]
    @extensions = args[1] ? args[1].squeeze(' ').gsub('.', '').split(',') : %w(css erb feature js haml html rb sass scss)
    @comments = []
    @stats = []
    initialize_comments
    initialize_stats
  end

  def extract
    Dir.glob("#{@path}/**/*.{#{@extensions.join(',')}}").each do |f| 
      ext = File.extname(f).gsub('.', '')
      @stats[@stats.index {|x| x[:extension] == ext}][:files] += 1
      body = File.open(f).read
      regex = case ext
              when 'html','erb'; /\<!\s*--(.*?)(--\s*\>)/m
              when 'js','css','scss'; /\/\*(.*?)\*\//m
              when 'feature','rb'; /#.*$/
              when 'sass'; /\/\/.*$/
              else; nil
              end
      next if regex.nil?
      res = body.match(regex).to_a
      @stats[@stats.index {|x| x[:extension] == ext}][:comments] += res.size 
      res.each do |comment|
        comment_hash = {:file => f, :comment => comment}
        @comments[@comments.index {|x| x[:extension] == ext}][:comments] << comment_hash 
      end
    end
  end

  def print_comments
    res = []
    res << ''
    @comments.each do |comment|
      comment[:comments].each do |c|
        res << c[:file]
        res << ''
        res << c[:comment]
        res << ''
        res << '---------------------------------------------'
      end
    end
    res << ''
    puts res.join("\n")
  end

  def print_stats
    res = []
    res << ''
    @stats.each do |stat|
      res << "  .#{stat[:extension].ljust(7)} #{stat[:files].to_s.rjust(10)} files #{stat[:comments].to_s.rjust(10)} comments"
    end
    res << ''
    puts res.join("\n")  
  end

private

  def initialize_comments
    @extensions.each do |ext|
      @comments << {:extension => ext, :comments => []}
    end
  end

  def initialize_stats
    @extensions.each do |ext|
      @stats << {:extension => ext, :files => 0, :comments => 0}
    end
  end

end

def run
  c = CommentExtractor.new(*ARGV)
  puts ''
  puts 'Preparing results...'
  c.extract
  c.print_comments
  c.print_stats
  puts ''
end

run if __FILE__ == $PROGRAM_NAME



