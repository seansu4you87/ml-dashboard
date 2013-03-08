namespace :summarize do

  desc 'Summarizing data from MLRS to Elastic Search'
  task hours: :environment do
    Hour.summarize
  end

end