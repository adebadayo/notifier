require 'net/http'
require 'uri'

class BacklogController < ApplicationController
  before_action :set_values

  def post_to_slack
    issues = fetch_issues
    priority = {}
    priority[:high] = []
    priority[:mid] = []
    priority[:low] = []
    issues.each do |issue|
      case issue["priority"]["name"]
      when "高"
        priority[:high] << issues
      when "中"
        priority[:mid] << issues
      when "低"
        priority[:low] << issues
      else
        priority[:low] << issues
      end
    end


    issue_count = issues.length
    issue_list_url = "https://#{@backlog_space_id}.backlog.jp/find/#{@backlog_prj_name}?issueTypeId=#{@backlog_issue_type_id}&statusId=1&statusId=2&statusId=3&sort=PRIORITY&order=true"

    text = <<~"TEXT"
      不具合残り *#{issue_count}件！* 
      高 : #{priority[:high].length}件 中 : #{priority[:mid].length}件 低 : #{priority[:low].length}件
      <#{issue_list_url}|不具合一覧>
    TEXT
    post_params = {
      token: @slack_oauth_token,
      channel: "#" + @slack_channel,
      text: text,
    }
    uri = URI.parse('https://slack.com/api/chat.postMessage')
    Net::HTTP.post_form uri, post_params
  end

  private
  def set_values
    @slack_oauth_token = ENV['SLACK_OAUTH_TOKEN']
    @slack_channel = ENV['SLACK_CHANNEL']
    @backlog_space_id = ENV['BACKLOG_SPACE_ID']
    @backlog_api_key = ENV['BACKLOG_API_KEY']
    @backlog_prj_id = ENV['BACKLOG_PROJECT_ID']
    @backlog_prj_name = ENV['BACKLOG_PROJECT_NAME']
    @backlog_issue_type_id = ENV['BACKLOG_ISSUE_TYPE_ID']
  end

  def fetch_issues
    get_params = "count=100&issueTypeId[]=#{@backlog_issue_type_id}&projectId[]=#{@backlog_prj_id}&statusId[]=1&statusId[]=2&statusId[]=3&apiKey=#{@backlog_api_key}"
    uri = URI.parse("https://#{@backlog_space_id}.backlog.jp/api/v2/issues?#{get_params}")
    response = Net::HTTP.get(uri)
    JSON.parse(response)
  end
end
