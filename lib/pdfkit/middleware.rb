class PDFKit
  
  class Middleware
    
    def initialize(app, options = {})
      @app = app
      @options = options
    end
        
    def call(env)
      @render_pdf = false
      set_request_to_render_as_pdf(env) if env['PATH_INFO'].match(/\.pdf$/)
      
      status, headers, response = @app.call(env)
      
      request = Rack::Request.new(env)
      if @render_pdf && headers['Content-Type'] =~ /text\/html|application\/xhtml\+xml/
        body = response.body
        
        body = translate_paths(body, env)
        
        @options.merge! find_options_in_meta(body)

        pdf = PDFKit.new(body, @options)
        body = pdf.to_pdf
        
        # Do not cache PDFs
        puts "DELETING CACHING"
        headers.delete('ETag')
        headers.delete('Cache-Control')
        
        headers["Content-Length"] = body.bytes.to_a.size.to_s
        headers["Content-Type"] = "application/pdf"
        
        response = [body]
      end
      
      [status, headers, response]
    end
    
    private
    
      #find pdf_header and pdf_footer
      def find_options_in_meta(body)
        found_options={}
        require 'rexml/document'
        xml_body = REXML::Document.new(body)
       
        xml_body.elements.each("html/head/meta[@name='pdfkit' @data-option-name='header']")  {
          |e| found_options.merge!(e.attributes["data-option-name"].to_sym => e.attributes["content"] )  }
        found_options
      end
    
      
    
      # Change relative paths to absolute
      def translate_paths(body, env)
        # Host with protocol
        root = env['rack.url_scheme'] + "://" + env['HTTP_HOST'] + "/"
        
        body.gsub!(/(href|src)=['"]\/([^\"']*|[^"']*)['"]/,'\1="'+root+'\2"')
      end
    
      def set_request_to_render_as_pdf(env)
        @render_pdf = true
        puts "Setting PDF mode"
        
        path = Pathname(env['PATH_INFO'])
        env['PATH_INFO'] = path.to_s.sub(/#{path.extname}$/,'') if path.extname == '.pdf'
        env['HTTP_ACCEPT'] = concat(env['HTTP_ACCEPT'], Rack::Mime.mime_type('.html'))
      end
      
      def concat(accepts, type)
        (accepts || '').split(',').unshift(type).compact.join(',')
      end
  
  end
end
