class QuestionsController < ApplicationController
  layout 'main'

  def index
    @title = "Questions"
  end

  def faq
    @title = "FAQ (Frequently Asked Questions)"
    @questions = Question.find(:all,
                               :conditions => "featured = 1",
                               :order => "-rank DESC, times_viewed DESC")
  end

	# Ask a question, also known as /contact
	def ask
		@question = Question.new
	end
	
	# Actually creates the question
	def send_question
    @question = Question.new(params[:question])
		@question.short_question = "Message from the contact form"
    if !@question.save then
      render :action => 'new'
    end
  end
	
end
