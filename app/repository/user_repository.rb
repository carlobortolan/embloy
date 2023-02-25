# frozen_string_literal: true
# TODO: Implement UserRepository
# TODO: ERROR CATCHING

class UserRepository
  def add_user(user)
    # ActiveRecord::Base.connection.execute("INSERT INTO users VALUES #{user}")
    query = "INSERT INTO users VALUES #{user}"
    binds = [ActiveRecord::Relation::QueryAttribute.new('user', user, ActiveRecord::Type::User.new)]
    ApplicationRecord.connection.exec_query(query, 'SQL', binds, prepare: true)
  end

  def find_user(user_id)
    # ActiveRecord::Base.connection.execute("SELECT * FROM users WHERE id = #{id};")
    query = "SELECT * FROM users WHERE user_id = #{user_id};"
    binds = [ActiveRecord::Relation::QueryAttribute.new('user_id', user_id, ActiveRecord::Type::Integer.new)]
    ApplicationRecord.connection.exec_query(query, 'SQL', binds, prepare: true)
  end

  def find_all_users
    ActiveRecord::Base.connection.execute("SELECT * FROM users;")
  end

  def delete_user(user_id)
    query = "REMOVE * FROM users WHERE user_id = #{user_id};"
    binds = [ActiveRecord::Relation::QueryAttribute.new('user_id', user_id, ActiveRecord::Type::Integer.new)]
    ApplicationRecord.connection.exec_query(query, 'SQL', binds, prepare: true)
  end

  def get_user_name(user_id)
    # ActiveRecord::Base.connection.query("SELECT first_name, last_name FROM accounts WHERE account_id = #{account_id}").each do |i|
    #  return i[0].to_s.concat(" #{i[1].to_s}")
    # end
    query = "SELECT first_name, last_name FROM users WHERE id = #{user_id}"
    binds = [ActiveRecord::Relation::QueryAttribute.new('id', user_id, ActiveRecord::Type::Integer.new)]
    result = ApplicationRecord.connection.exec_query(query, 'SQL', binds, prepare: true)
    unless result[0].nil?
      result[0].values_at(:first_name).to_s.concat(result[0].values_at(:last_name).to_s)
      result[0].values_at("first_name")[0].concat(" " + result[0].values_at("last_name")[0].to_s)
    end
  end
end
