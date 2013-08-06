
class BaseController < ActionController::Base
	@@mockdata = [
			{
				:name => "Push Ups",
				:time => 4,
				:part => "Arms",
				:id => 1
			},
			{
				:name => "Sit Ups",
				:time => 3,
				:part => "Abs",
				:id => 2
			},
			{
				:name => "Chin Ups",
				:time => 20,
				:part => "Arms",
				:id => 3
			},
			{
				:name => "Leg Raises",
				:time => 5,
				:part => "Abs",
				:id => 4
			},
			{
				:name => "Lunges",
				:time => 6,
				:part => "Legs",
				:id => 5
			}
		]
	def index
	end


	def exercises
		respond_to do |format|
			format.html { render json: @@mockdata }
			if params[:callback]
	 		format.js { render :json => @@mockdata, :callback => params[:callback] }
			else
			format.json { render json: @@mockdata}
			end
		end
	end
end
