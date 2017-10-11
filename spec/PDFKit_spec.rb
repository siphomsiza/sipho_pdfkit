require 'spec_helper'

describe PDFKit do
  
  context "initialization" do
    it "should accept HTML as the source" do
      pdfkit = PDFKit.new('<h1>Oh Hai</h1>')
      pdfkit.source.should be_html
      pdfkit.source.to_s.should == '<h1>Oh Hai</h1>'
    end
    
    it "should accept a URL as the source" do
      pdfkit = PDFKit.new('http://google.com')
      pdfkit.source.should be_url
      pdfkit.source.to_s.should == 'http://google.com'
    end
    
    it "should accept a File as the source" do
      file_path = File.join(SPEC_ROOT,'fixtures','example.html')
      pdfkit = PDFKit.new(File.new(file_path))
      pdfkit.source.should be_file
      pdfkit.source.to_s.should == file_path
    end
    
    it "should parse the options into a cmd line friedly format" do
      pdfkit = PDFKit.new('html', :page_size => 'Letter')
      pdfkit.options.should have_key('--page-size')
    end
    
    it "should provide default options" do
      pdfkit = PDFKit.new('<h1>Oh Hai</h1>')
      ['--disable-smart-shrinking', '--margin-top', '--margin-right', '--margin-bottom', '--margin-left'].each do |option|
        pdfkit.options.should have_key(option)
      end
    end
    
    it "should not have any stylesheedt by default" do
      pdfkit = PDFKit.new('<h1>Oh Hai</h1>')
      pdfkit.stylesheets.should be_empty
    end
  end
  
  context "command" do
    it "should contstruct the correct command" do
      pdfkit = PDFKit.new('html', :page_size => 'Letter', :toc_l1_font_size => 12)
      pdfkit.command.should include('wkhtmltopdf')
      pdfkit.command.should include('--page-size Letter')
      pdfkit.command.should include('--toc-l1-font-size 12')
    end
    
    it "will not include default options it is told to omit" do
      pdfkit = PDFKit.new('html')
      pdfkit.command.should include('--disable-smart-shrinking')
      pdfkit = PDFKit.new('html', :disable_smart_shrinking => false)
      pdfkit.command.should_not include('--disable-smart-shrinking')
    end
    
    it "should encapsulate string arguments in quotes" do
      pdfkit = PDFKit.new('html', :header_center => "foo [page]")
      pdfkit.command.should include('--header-center "foo [page]"')
    end
    
    it "read the source from stdin if it is html" do
      pdfkit = PDFKit.new('html')
      pdfkit.command.should match(/ - -$/)
    end
    
    it "specify the URL to the source if it is a url" do
      pdfkit = PDFKit.new('http://google.com')
      pdfkit.command.should match(/ http:\/\/google\.com -$/)
    end
    
    it "should specify the path to the source if it is a file" do
      file_path = File.join(SPEC_ROOT,'fixtures','example.html')
      pdfkit = PDFKit.new(File.new(file_path))
      pdfkit.command.should match(/ #{file_path} -$/)
    end

    [:header, :footer].each do |type|
      context "with #{type}" do
        let(:regexp){ %r{ --#{type}-html (/tmp/pdfkit[\d_]+\.html) } }
        let(:pdfkit){ PDFKit.new('foo', type => 'bar') }

        it "should add #{type} as file" do
          pdfkit.command.should =~ regexp
        end

        it "should put the #{type} into a tempfile" do
          tempfile = pdfkit.command.match(regexp)[1]
          File.read(tempfile).should == 'bar'
        end
      end
    end
  end

  context "#to_pdf" do
    it "should generate a PDF of the HTML" do
      pdfkit = PDFKit.new('html', :page_size => 'Letter')
      pdf = pdfkit.to_pdf
      pdf[0...4].should == "%PDF" # PDF Signature at beginning of file
    end
    
    it "should have the stylesheet added to the head if it has one" do
      pdfkit = PDFKit.new("<html><head></head><body>Hai!</body></html>")
      css = File.join(SPEC_ROOT,'fixtures','example.css')
      pdfkit.stylesheets << css
      pdfkit.to_pdf
      pdfkit.source.to_s.should include("<style>#{File.read(css)}</style>")
    end
    
    it "should prepend style tags if the HTML doesn't have a head tag" do
      pdfkit = PDFKit.new("<html><body>Hai!</body></html>")
      css = File.join(SPEC_ROOT,'fixtures','example.css')
      pdfkit.stylesheets << css
      pdfkit.to_pdf
      pdfkit.source.to_s.should include("<style>#{File.read(css)}</style><html>")
    end
    
    it "should throw an error if the source is not html and stylesheets have been added" do
      pdfkit = PDFKit.new('http://google.com')
      css = File.join(SPEC_ROOT,'fixtures','example.css')
      pdfkit.stylesheets << css
      lambda { pdfkit.to_pdf }.should raise_error(PDFKit::ImproperSourceError)
    end
  end
  
  context "#to_file" do
    before do
      @file_path = File.join(SPEC_ROOT,'fixtures','test.pdf')
      File.delete(@file_path) if File.exist?(@file_path)
    end
    
    after do
      File.delete(@file_path)
    end
    
    it "should create a file with the PDF as content" do
      pdfkit = PDFKit.new('html', :page_size => 'Letter')
      pdfkit.expects(:to_pdf).returns('PDF')
      file = pdfkit.to_file(@file_path)
      file.should be_instance_of(File)
      File.read(file.path).should == 'PDF'
    end
  end
  
end
