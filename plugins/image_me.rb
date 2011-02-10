require 'googleajax'
require 'tempfile'

class ImageMe < CampfireBot::Plugin
  BASE_URL = 'http://images.google.com/images'
  
  on_command 'image me', :random_image
  
  def random_image(msg)
    msg.speak(random_url(msg[:message]))
  end
  
  private

  def fetch_image_urls(term)
    GoogleAjax.referrer = 'http://www.bookrenter.com'
    GoogleAjax::Search.images(term).first.last.map { |e| e[:unescaped_url] } rescue []
  end
  
  def random_url(term)
    image_urls = fetch_image_urls(term)
    image_urls[rand(image_urls.size)]
  end  
end