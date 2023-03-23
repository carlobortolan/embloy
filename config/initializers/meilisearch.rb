# Config for meilisearch (https://github.com/meilisearch/meilisearch-rails)
# $ docker pull getmeili/meilisearch:latest
# $ docker run -it --rm -p 7700:7700 getmeili/meilisearch:latest meilisearch --master-key=h43ZVq2Kj47jN9s5V-fnNBJRWV9gsIt5zs1gKYwFQeI

MeiliSearch::Rails.configuration = {
  meilisearch_url: ENV['MEILISEARCH_URL'],
  meilisearch_api_key: ENV['MEILISEARCH_API_KEY'],
  timeout: 2,
  max_retries: 1,
}