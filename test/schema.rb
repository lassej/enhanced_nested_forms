ActiveRecord::Schema.define(:version => 0) do
  create_table :projects, :force => true do |t|
    t.integer :user_id
    t.string :name
  end

  create_table :tasks, :force => true do |t|
    t.integer :project_id
    t.string :name
  end

  create_table :users, :force => true do |t|
    t.integer :task_id
    t.string :name
  end
end
