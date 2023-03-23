# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
require 'faker'
require 'benchmark'

users = []
jobs = []
applications = []

#=> CREATE USERS
elapsed_user = Benchmark.measure do
  1.times do |i|
    begin
      name_f = Faker::Name.first_name
      name_l = Faker::Name.last_name
      address_full = Faker::Address
      user = User.new(
        first_name: name_f,
        last_name: name_l,
        email: name_f + name_l + "@embloy.com",
        password: Faker::Alphanumeric.alpha(number: 10),
        longitude: Faker::Number.decimal,
        latitude: Faker::Number.decimal,
        country_code: address_full.country_code,
        postal_code: address_full.postcode,
        city: address_full.city,
        address: address_full.street_address,
        date_of_birth: DateTime.parse(Time.at(rand * Time.now.to_i).to_s),
        created_at: Faker::Date.to_s,
        updated_at: Faker::Date.to_s,
        activity_status: [0, 1].sample,
        image_url: "https://picsum.photos/200/300?random=#{i}",
        view_count: rand(1100)
      )
      users.push(user)
    rescue Exception => exception
      puts exception.message
    end
  end
  puts "FINISHED CREATING USERS"
end
puts "Finished in #{elapsed_user.real} seconds."
User.import(users)

#=> CREATE JOBS POSTGRESQL
elapsed_job = Benchmark.measure do
  1000.times do |i|
    begin
      address_full = Faker::Address
      job = Job.new(
        job_type: Faker::Job.field,
        job_type_value: rand(29),
        job_status: 0,
        status: 'public',
        user_id: (Faker::Number.number % User.count) + 1,
        duration: Faker::Number.number(digits: 4),
        code_lang: address_full.country_code,
        title: Faker::Job.title,
        position: Faker::Job.position,
        description: Faker::GreekPhilosophers.quote,
        key_skills: Faker::Job.key_skill,
        salary: Faker::Number.decimal,
        currency: Faker::Currency.name,
        image_url: "https://picsum.photos/200/300?random=#{i}",
        start_slot: DateTime.parse(Time.at(rand * Time.now.to_i).to_s),
        longitude: Faker::Number.decimal,
        latitude: Faker::Number.decimal,
        country_code: address_full.country_code,
        postal_code: address_full.postcode,
        city: address_full.city,
        address: address_full.street_address,
        view_count: rand(1100),
        boost: rand(100),
        employer_rating: rand(5),
        created_at: Faker::Date.to_s,
        updated_at: Faker::Date.to_s,
      )
      jobs.push(job)
    rescue Exception => exception
      puts exception.message
    end
  end
  puts "FINISHED CREATING JOBS"
end
puts "Finished in #{elapsed_job.real} seconds."
Job.import(jobs)