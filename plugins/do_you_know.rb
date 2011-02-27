require 'uri'
require 'open-uri'
require 'active_support'
require 'zlib'

class DoYouKnow < CampfireBot::Plugin
  on_command 'do you know', :do_you_know_command
  
  def do_you_know_command(msg)
    do_you_know(msg[:message]).each do |statement|
      msg.speak(statement)
    end
  end
  
private

  def fetch_json_hash(url, deflate = false)
    response = open(url)
    response = Zlib::GzipReader.new(response) if deflate
    return ActiveSupport::JSON.decode(response.read)
  end

  def dont_know_answer(question)
    message = config['dont_know_responses'].rand || "Sorry, I don't know the answer to that.  Try"
    return "#{message} #{googling_link(question)}."
  end

  def googling_link(question)
    "<a href='http://www.google.com?q=#{URI.escape(question)}'>googling it</a>"
  end

  def do_you_know(question)
    statements = []
    begin
      search_response = fetch_json_hash("http://ajax.googleapis.com/ajax/services/search/web?v=1.0&rsz=1&key=AIzaSyBv1_qJoAOpBZg3UQ55ebSApmIOmSoFs3Q&q=site:stackoverflow.com%20#{URI.escape(question)}")
      search_result = search_response['responseData']['results'][0]
      if search_result
        question_id = search_result['url'].sub(/^.*questions\//, '').sub(/\/.*$/, '')
        question_response = fetch_json_hash("http://api.stackoverflow.com/1.1/questions/#{question_id}?body=true", true)
        question = "I know this: #{question_response['questions'][0]['title']}"
        question = "#{question} <a href='http://stackoverflow.com/questions/#{question_id}'>*</a>"
      
        answer_response = fetch_json_hash("http://api.stackoverflow.com/1.1/questions/#{question_id}/answers?sort=votes&body=true&pagesize=1", true)
        answer = answer_response['answers'][0]
        if answer
          statements << question
          statements << answer['body']
        end
      end
      if statements.empty?
        statements << dont_know_answer(question)
      end
    rescue Exception => e
      statements << "Sorry, my brain hurts. I think it has to do with #{e}."
    end
  
    return statements
  end
end