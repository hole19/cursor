module Cursor
  module PageScopeMethods
    # Specify the <tt>per_page</tt> value for the preceding <tt>page</tt> scope
    #   Model.page(3).per(10)
    def per(num)
      if (n = num.to_i) <= 0
        self
      elsif max_per_page && max_per_page < n
        limit(max_per_page)
      else
        limit(n)
      end
    end

    def result
      @_cursor_result_set ||= all.to_a
    end

    # To avoid multiple db hist on these 2 methods, 
    # enable perform_caching to perform this on cached result
    def next_cursor
      @_next_cursor ||= result.last.try(default_paginate_by)
    end

    def predicted_next_cursor
      return @_predicted_next_cursor if defined? @_predicted_next_cursor
      @_predicted_next_cursor = nil
      return @_predicted_next_cursor unless next_cursor && (since_query || result.size == all.limit_value)
      
      without_since do
        @_predicted_next_cursor = next_cursor if all.where("#{table_name}.#{default_paginate_by} #{direction == :after ? '>' : '<'} ?", next_cursor).exists?
      end

      @_predicted_next_cursor
    end

    def prev_cursor
      @_prev_cursor ||= result[0].try(default_paginate_by)
    end

    def since_cursor
      direction == :after ? next_cursor : prev_cursor
    end

    def next_url request_url
      direction == :after ? 
        after_url(request_url, predicted_next_cursor) :
        before_url(request_url, predicted_next_cursor)
    end

    def prev_url request_url
      direction == :after ? 
        before_url(request_url, prev_cursor) :
        after_url(request_url, prev_cursor)
    end

    def refresh_url request_url
      cursor_url(request_url, Cursor.config.since_param_name.to_s, since_cursor)
    end

    def before_url request_url, cursor
      cursor_url(request_url, Cursor.config.before_param_name.to_s, cursor)
    end

    def after_url request_url, cursor
      cursor_url(request_url, Cursor.config.after_param_name.to_s, cursor)
    end

    def cursor_url request_url, cursor_param, cursor
      base, params = url_parts(request_url)
      params.merge!(cursor_param => cursor) unless cursor.nil?
      params.to_query.length > 0 ? "#{base}?#{CGI.unescape(params.to_query)}" : base
    end

    def url_parts request_url
      base, params = request_url.split('?', 2)
      params = Rack::Utils.parse_nested_query(params || '')
      params.stringify_keys!
      params.delete(Cursor.config.before_param_name.to_s)
      params.delete(Cursor.config.after_param_name.to_s)
      params.delete(Cursor.config.since_param_name.to_s)
      [base, params]
    end

    def since_query
      @since_query ||= direction == :before ? all.where_values.find { |v| v.is_a?(String) && /#{table_name}.#{default_paginate_by} >/ =~ v } : nil
    end

    def without_since
      if since_query
        since_index = all.where_values.index(since_query)
        all.where_values.delete_at(since_index)
      end

      yield

      all.where_values.insert(since_index, since_query) if since_query
    end

    def direction
      return :after if prev_cursor.nil? && next_cursor.nil?
      @_direction ||= prev_cursor < next_cursor ? :after : :before
    end

    def pagination request_url
      h = {
        next_cursor:  predicted_next_cursor,
        prev_cursor:  prev_cursor,
        since_cursor: since_cursor
      }
      h[:next_url]    = next_url(request_url)    unless predicted_next_cursor.nil?
      h[:prev_url]    = prev_url(request_url)    unless prev_cursor.nil?
      h[:refresh_url] = refresh_url(request_url) unless since_cursor.nil?
      h
    end
  end
end
