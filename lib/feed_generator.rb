# frozen_string_literal: true
# @author Jan Hummel, Carlo Bortolan
# This class creates a feed from a set of jobs matching the input parameters by the user.

class FeedGenerator

  # job wird nach start_slot sortiert/ je nach time aus my args gefiltert. Das Ergebnis wird nun nach Distanz sortiert ausgegeben
  # n(= limit)-jobs im radius werden gefiltert und ausgegeben
  # @param prefiltered [Array] array of jobs from database
  # @param my_args [my_args] user input
  # @return relevant job
  # prefiltered = [{ "job_id" => int>=0, "start_slot" => "year-month-date hours:minutes:seconds +hhmm", "location" => { "latitude" => float>=0, "longitude" => float>=0 } },
  # my_args = { "account_id" => int>=0, "latitude" => float>=0.0, "longitude" => float>=0.0, "radius" => float>=0.0, "time" => int [1, 48], "limit" => int>=0 }
  def self.initialize_feed(prefiltered, my_args)
    puts "DEBUG ON"
    puts prefiltered
    puts my_args
    puts "DEBUG OFF"

    if prefiltered.nil? || my_args.nil? || prefiltered.empty?
      puts "input was nil"
      return [401]
    end
    # if my_args["account_id"].nil? || !my_args["account_id"].is_a?(Integer) || my_args["account_id"] < 0
    # puts "account_id not correct (@my_args)"
    # return [401]
    # end
    if my_args["latitude"].nil? || !my_args["latitude"].is_a?(Float)
      puts "latitude not correct (@my_args)"
      return [401]
    end
    if my_args["longitude"].nil? || !my_args["longitude"].is_a?(Float)
      puts "longitude not correct (@my_args)"
      return [401]
    end
    if my_args["radius"].nil? || my_args["radius"] < 0
      my_args["radius"] = 50.0
      puts "radius not correct (@my_args)"
    elsif !my_args["radius"].is_a?(Float)
      my_args["radius"] = my_args["radius"].to_f
    end

    if my_args["time"].nil? || !my_args["time"].is_a?(Time)
      my_args["time"] = Time.now
      puts "time not correct (@my_args)"
    end
    if my_args["limit"].nil? || !my_args["limit"].kind_of?(Integer) || my_args["limit"] < 0
      puts "limit not correct (@my_args)"
      my_args["limit"] = 50
    end
    prefiltered.each do |i|
      if i.nil?
        puts "element in prefiltered was nil (@prefiltered)"
        return [401]
      end
      if i["job_id"].nil? || !i["job_id"].is_a?(Integer) || i["job_id"] < 0
        puts "account_id not correct (@prefiltered)"
        return [401]
      end
      if i["start_slot"].nil? || !(i["start_slot"].is_a?(Time))
        begin
          i["start_slot"] = Time.parse(i["start_slot"])
          puts "correcting start-slot"
        rescue
          puts "start_slot correct (@prefiltered)"
          return [401]
        end
      end
      if i["latitude"].nil? || !i["latitude"].is_a?(Float)
        puts "latitude not correct (@prefiltered)"
        return [401]
      end
      if i["longitude"].nil? || !i["longitude"].is_a?(Float)
        puts "latitude not correct (@prefiltered)"
        return [401]
      end
      # TODO: CLEARING DISTANCE
      unless i["distance"].nil?
        # puts "correcting distance (@prefiltered)"
        i["distance"] = nil
      end
    end
    r1 = match_jobs(prefiltered, my_args)
    puts "R1 === #{r1}"
    generate_feed(r1, my_args["radius"], my_args["limit"])
  end

  private

  #@return [Array] sorted array
  def self.merge_sort(array, tgt)
    # klassische Merge sort implementierung mit einem Parameter. Die methode nimmt ein Array mit Hashes an z.b. [{...,start_slot:"07:00:00",target_slot:15,...}] und einen sortierungs parameter (tgt) (z.b. "target_slot"). DIe hashes in array werden nahc diesem sortierparameter soritert.

    if array.length <= 1
      return array
    end

    array_size = array.length
    middle = (array.length / 2).round

    left_side = array[0...middle]
    right_side = array[middle...array_size]

    sorted_left = merge_sort(left_side, tgt)
    sorted_right = merge_sort(right_side, tgt)

    merge(array, sorted_left, sorted_right, tgt)
    array
  end

  def self.merge(array, sorted_left, sorted_right, tgt)
    left_size = sorted_left.length
    right_size = sorted_right.length
    array_pointer = 0
    left_pointer = 0
    right_pointer = 0

    while left_pointer < left_size && right_pointer < right_size
      if sorted_left[left_pointer].values_at(tgt)[0] < sorted_right[right_pointer].values_at(tgt)[0]
        array[array_pointer] = sorted_left[left_pointer]
        left_pointer += 1
      else
        array[array_pointer] = sorted_right[right_pointer]
        right_pointer += 1
      end
      array_pointer += 1
    end

    while left_pointer < left_size
      array[array_pointer] = sorted_left[left_pointer]
      left_pointer += 1
      array_pointer += 1
    end

    while right_pointer < right_size
      array[array_pointer] = sorted_right[right_pointer]
      right_pointer += 1
      array_pointer += 1
    end

    array
  end

  # Combines binary search with binary compare: Returns index of next largest element in array
  # @param array [Array] sorted array
  # @param search_item [args] relevant element
  # @param tgt [String] search parameter
  def self.binary_compare (array, search_item, tgt)
    low = 0
    high = array.length - 1
    if array[high].values_at(tgt)[0] <= search_item
      return array.length
    end

    while high - low > 1
      mid = (high + low) / 2
      array[mid].values_at(tgt)[0] < search_item ? low = mid + 1 : high = mid
    end

    if array[low].values_at(tgt)[0] == search_item
      low + 1
    else
      array[high].values_at(tgt)[0] == search_item ? high + 1 : high - 1
    end
  end

  # TODO: use binary method instead of linear
  # Basic linear search to return lower and upper bound of a job array depending on the start_slot with a deviation of +-day (=3600s*24)
  # @param array [Array] sorted array of jobs
  # @param search_item [Integer] time instance as Interger for reference
  # @param tgt [String] search parameter
  # @return [[Integer, Integer]] index of lower and upper bound
  def self.time_bounds (array, search_item, tgt)
    # puts "INPUT = #{array[0].values_at(tgt)[0].to_i}"
    # puts "INPUT = #{array[1].values_at(tgt)[0].to_i}"
    # puts "TGT = #{search_item}"
    bound = [0, 0]
    array.each_with_index do |value, index|
      if value.values_at(tgt)[0].to_i <= search_item - 3600 * 24 - 1
        bound[0] = index + 1
      elsif value.values_at(tgt)[0].to_i <= search_item + 3600 * 24 - 1
        bound[1] = index + 1
      end
    end
    bound
  end

  # schaut ob in sorted_args unter target_slot die "zeit id" äquivalent zu time ist. es wird das intervall an elementen in sorted_args ausgegeben wo das zutrifft
  # @param sorted_args [Array] sorted array of jobs
  # @param time [Time] target time
  # @return [Array] Interval that matches target time
  def self.find_time(sorted_args, time)
    bounds = time_bounds(sorted_args, time.to_i + 1, "start_slot")
    low = bounds[0]
    high = bounds[1]

    if low == -1 || low == sorted_args.length || low >= high
      return [401]
    end
    [low, high - 1]
  end

  # Calculates distance between two coordinates A, B in kilometers
  # @param loc1 [[Float, Float]] coordinate A
  # @param loc2 [[Float, Float]] coordinate B
  def self.distance(loc1, loc2)
    rad_per_deg = Math::PI / 180 # PI / 180
    rm = 6371 * 1000 # Earth radius in meters

    d_lat_rad = (loc2[0] - loc1[0]) * rad_per_deg # Delta, converted to rad
    d_lon_rad = (loc2[1] - loc1[1]) * rad_per_deg

    lat1_rad, lon1_rad = loc1.map { |i| i * rad_per_deg }
    lat2_rad, lon2_rad = loc2.map { |i| i * rad_per_deg }

    a = Math.sin(d_lat_rad / 2) ** 2 + Math.cos(lat1_rad) * Math.cos(lat2_rad) * Math.sin(d_lon_rad / 2) ** 2
    c = 2 * Math::atan2(Math::sqrt(a), Math::sqrt(1 - a))

    rm * c # Delta in meters
  end

  # schreibt in jeden job aus jobliste die entfernung zwischen user standort und job ort und gibt neue liste aus
  # @param user_pos [Hashmap] position of user
  # @param args [Job] job list
  # @return args job list with updated distance
  def self.calculate_distance(user_pos, args)
    user_lat = user_pos.values_at("latitude")[0]
    user_lon = user_pos.values_at("longitude")[0]
    args.each do |job|
      job_lat = job.values_at("latitude")[0]
      job_lon = job.values_at("longitude")[0]

      job["distance"] = distance([user_lat, user_lon], [job_lat, job_lon])
    end
    args
  end

  # hashes die nicht die eigenschaften in my_args beschrieben erfüllen werden aus args rausgeschmissen
  # args = [{},...,{}]
  # @param args [Array] array of jobst
  # @param my_args [Array] user input
  # @return [Array] containing relevant jobs
  def self.match_jobs(args, my_args)
    # puts "T1"
    time = my_args.select { |k| k.to_s.include? "time" }.values[0]
    args = merge_sort(args, "start_slot")
    rng = find_time(args, time)
    # puts "args = #{args}, time = #{time}, \r\n nng = #{rng}"

    if rng == [401]
      # rng = find_time(args, time + 3600 * 24)
      if rng == [401]
        # rng = find_time(args, time - 3600 * 24)
        if rng == [401]
          return [401]
        end
      end
    end
    args = args.slice(rng[0], ((rng[1] + 1) - rng[0]))
    merge_sort(calculate_distance(my_args, args), "distance")
  end

  # @param jobs [jobs] input
  # @param radius [Float] target radius
  # @param limit [Integer] Limit of result
  # @return [Array] containing relevant jobs
  def self.generate_feed(jobs, radius, limit)
    if jobs == [401]
      return [401]
    end

    pos = FeedGenerator.binary_compare(jobs, radius, "distance")
    puts pos

    # No match
    if pos == -1 || jobs[0..pos].empty?
      return [401]
    end

    # If number of matched jobs is greater than 'limit', exactly 'limit'-number of jobs will be returned
    # jobs.slice(0, pos).length > limit ? jobs.slice(0, limit) : jobs.slice(0, pos)
    jobs[0..pos]
  end
end

