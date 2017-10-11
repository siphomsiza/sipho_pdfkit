$LOAD_PATH << File.join(File.dirname(__FILE__), '..', 'lib')
require 'PDFKit'
PDFKit.new(
  "<h1 style='height:2000px'>Some content</h1>",
  :page_size => 'A4',
  :header=>"<h1>A header...</h1>",
  :footer => "<h1>A Footer</h1>"
).to_file 'headers.pdf'