# frozen_string_literal: true
# TODO: Add missing methods to AccountRepository
# TODO: ERROR CATCHING
class AccountRepository
  def get_account(account_id)
    #      ActiveRecord::Base.connection.query("SELECT * FROM accounts WHERE account_id = #{account_id}")
    query = "SELECT * FROM accounts WHERE account_id = #{account_id}"
    binds = [ActiveRecord::Relation::QueryAttribute.new('account_id', account_id, ActiveRecord::Type::Integer.new)]
    ApplicationRecord.connection.exec_query(query, 'SQL', binds, prepare: true)

  end

  def get_account_name(account_id)
    # ActiveRecord::Base.connection.query("SELECT first_name, last_name FROM accounts WHERE account_id = #{account_id}").each do |i|
    #  return i[0].to_s.concat(" #{i[1].to_s}")
    # end
    query = "SELECT first_name, last_name FROM accounts WHERE account_id = #{account_id}"
    binds = [ActiveRecord::Relation::QueryAttribute.new('account_id', account_id, ActiveRecord::Type::Integer.new)]
    result = ApplicationRecord.connection.exec_query(query, 'SQL', binds, prepare: true)
    unless result[0].nil?
      result[0].values_at(:first_name).to_s.concat(result[0].values_at(:last_name).to_s)
      result[0].values_at("first_name")[0].concat(" " + result[0].values_at("last_name")[0].to_s)
    end
  end
end
