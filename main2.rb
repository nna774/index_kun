require 'google/cloud/storage'
require 'haml'
require 'optparse'
bucket_name = nil
prefix = nil

opt = OptionParser.new
opt.on('-b bucket', '--bucket bucket') { |b| bucket_name = b }
opt.on('-p prefix', '--prefix prefix') { |p| prefix = p }

opt.parse!(ARGV)
if bucket_name.nil?
  raise 'need bucket(-b)'
end
if prefix.nil?
  raise 'need prefix(-p)'
end


class Result
  attr_reader :prefix, :files

  def initialize(prefix:, files:)
    @prefix = prefix
    @files = files
  end
end

def render(list)
  template = File.read 'views/index.html.haml'
  Haml::Engine.new(template).render(Object.new, { prefix: list.prefix, files: list.files })
end

def relative_path(prefix, path)
  "./#{path[prefix.length .. -1]}"
end

module IndexKun
  class FileRecorder
    def initialize(content)
      @content = content
    end
    def record(path:)
      File.write(path, @content)
    end
  end
end

def continue
  print 'Press enter to continue'
  gets
end

storage = Google::Cloud::Storage.new

bucket = storage.bucket bucket_name
files = bucket.files prefix: prefix, delimiter: '/'
result = files.map { |file| { name: relative_path(prefix, file.name), content_type: file.content_type } }
result.concat(files.prefixes.map {|p| { name: relative_path(prefix, p) } })
puts res = render(Result.new( 
  prefix: prefix,
  files: result,
))

puts
puts "save above to gs://#{bucket_name}/#{prefix}index.html"
continue

bucket.create_file StringIO.new(res), "#{prefix}index.html"
