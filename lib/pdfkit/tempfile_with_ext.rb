# borrowed from http://github.com/mileszs/wicked_pdf
require 'tempfile'

class TempfileWithExt < Tempfile
  # Replaces Tempfile's +make_tmpname+ with one that honors file extensions.
  def make_tmpname(basename, n)
    extension = File.extname(basename)
    n = n.nil? ? Time.now.strftime("%Y%m%d%H%M") : n
    sprintf("%s_%d_%d%s", File.basename(basename, extension), $$, n, extension)
  end

  def self.string_to_file(string, filename='foo')
    path = nil
    open(filename) do |f|
      f.write string
      path = f.path
    end
    path
  end
end
