module DegreesOfSeparation
	require 'httparty'
	
	#main function
	def get_degrees_of_separation
		puts "Give Input"
		input = gets.split(' ')
		return "Please give two actor names" unless input[1] && input[2]#ensure two actor names are given as input
		return  "Degrees of Separation: 0" if input[1] == input[2]
		degrees_of_separation = 0
		@movies_super_set = []
		if get_related_movies(input[2]).length < get_related_movies(input[1]).length#find actor with least number of movies associated
			actors_set = [input[2]]
			second_actor = input[1]
		else
			actors_set = [input[1]]
			second_actor = input[2]
		end
		@actors_super_set = actors_set
		@data = {actors_set[0] => {}}
		while(1)
			degrees_of_separation += 1
			actors_set1 = actors_set.uniq
			actors_set = []
				actors_set1.each{|first_actor|
				result = compare_actors(first_actor, second_actor)
				return print_output(second_actor, degrees_of_separation) if result == "present"
				actors_set.concat(result)#actors set for next iteration
			}
			break if degrees_of_separation > 5
		end
		return "Actors are not related"
	end	

	def compare_actors(actor1, actor2)
		data = deep_find(@data, actor1)
		movies = get_related_movies(actor1)
		@movies_super_set.concat(movies)
		movies.each{|movie|
			result_actors = get_related_actors(movie)
			data[movie] =  Hash[result_actors.map {|key, value| [key, {}]}]
			return 'present' if result_actors.include? actor2
			@actors_super_set.concat(result_actors)
		}
		data.values.map(&:keys).flatten.uniq
	end	

	def get_related_movies(actor)
		movies = []
		result = get_data(actor)	
		result["movies"].each{|movie|
			movies << movie["url"] unless @movies_super_set.include? movie["url"]
		} unless result.nil?
		movies.uniq
	end	

	def get_related_actors(movie)
		actors = []
		result = get_data(movie)
		(result["cast"]+result["crew"]).each{|cast|
			actors << cast["url"] unless @actors_super_set.include? cast["url"]
		} unless result.nil?
		actors.uniq
	end	
	

	def get_data(input)
		begin 
			url = "http://data.moviebuff.com/"+input.to_s
			response = HTTParty.get(url)
			result = JSON.parse(response.body)
		rescue => e
		end
		result
	end	

	#find hash keys in nested hash
	def deep_find(obj, key)
		return obj[key] if obj.respond_to?(:key?) && obj.key?(key)
		if obj.is_a? Enumerable
			found = nil
			obj.find { |*a| found = deep_find(a.last, key,) }
			found
		end
	end	

	#find hash key parents in nested hash
	def deep_find_parent(obj, key)
		return @parent if obj.respond_to?(:key?) && obj.key?(key)
		if obj.is_a? Enumerable
			found = nil
			@parent = obj[0]
			obj.find { |*a| found = deep_find_parent(a.last, key) }
			found
		end
	end	

	def print_output(second_actor, degrees_of_separation)
		result = [second_actor]
		while(1)
			@parent = nil
			parent = deep_find_parent(@data, parent||second_actor)
			result << parent unless parent.nil?
			break if @parent.nil?
		end
		index = 0
		puts "Degrees of Separation: #{degrees_of_separation}"
		while(1)
			actor = result[index]
			movie = result[index+1]
			related_actor = result[index+2]
			movie_data = get_data(movie)
			puts "\nMovie: #{movie_data['name']}"
			actors = movie_data["cast"] + movie_data["crew"]
			actors.each{|cast|
				if cast["url"] == actor
					puts "#{cast["role"]} : #{cast["name"]}"
					break
				end
			}
			actors.each{|cast|
				if cast["url"] == related_actor
					puts "#{cast["role"]} : #{cast["name"]}"
					break
				end
			}
			index += 2
			break if result[index+1].nil?
		end
	end

end
