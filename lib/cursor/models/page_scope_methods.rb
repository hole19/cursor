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

    # To avoid multiple db hist on these 2 methods, 
    # enable perform_caching to perform this on cached result
    def next_cursor
      @_next_cursor ||= all.last.try(default_paginate_by)
    end

    def prev_cursor
      @_prev_cursor ||= all[0].try(default_paginate_by)
    end

    def since_cursor
      direction == :after ? next_cursor : prev_cursor
    end

    def next_url request_url
      direction == :after ? 
        after_url(request_url, next_cursor) :
        before_url(request_url, next_cursor)
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

    def direction
      return :after if prev_cursor.nil? && next_cursor.nil?
      @_direction ||= prev_cursor < next_cursor ? :after : :before
    end

    def pagination request_url
      h = {
        next_cursor:  next_cursor,
        prev_cursor:  prev_cursor,
        since_cursor: since_cursor
      }
      h[:next_url]    = next_url(request_url)    unless next_cursor.nil?
      h[:prev_url]    = prev_url(request_url)    unless prev_cursor.nil?
      h[:refresh_url] = refresh_url(request_url) unless since_cursor.nil?
      h
    end
  end
end
