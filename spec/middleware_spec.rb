require 'spec_helper'

describe PDFKit::Middleware do
  describe "#translate_paths" do
    before do
      @pdf = PDFKit::Middleware.new({})
      @env = {'REQUEST_URI' => 'http://example.com/document.pdf', 'rack.url_scheme' => 'http', 'HTTP_HOST' => 'example.com'}
    end

    it "should correctly parse relative url with single quotes" do
      @body = %{<html><head><link href='/stylesheets/application.css' media='screen' rel='stylesheet' type='text/css' /></head><body><img alt='test' src='/test.png' /></body></html>}
      body = @pdf.send :translate_paths, @body, @env
      body.should == "<html><head><link href=\"http://example.com/stylesheets/application.css\" media='screen' rel='stylesheet' type='text/css' /></head><body><img alt='test' src=\"http://example.com/test.png\" /></body></html>"
    end

    it "should correctly parse relative url with double quotes" do
      @body = %{<link href="/stylesheets/application.css" media="screen" rel="stylesheet" type="text/css" />}
      body = @pdf.send :translate_paths, @body, @env
      body.should == "<link href=\"http://example.com/stylesheets/application.css\" media=\"screen\" rel=\"stylesheet\" type=\"text/css\" />"
    end
    
    it "should detect special pdfkit meta tags" do
      @body = %{<html><head><meta name="pdfkit" content="http://www.example.com/header.html" data-option-name="header" /></head></html>}
      body = @pdf.send :find_options_in_meta, @body
      body.should have_key(:header)
    end
    
  end
end
