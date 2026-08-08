# frozen_string_literal: true

class Publisher
  def name
    raise NotImplementedError
  end

  def front_matter_key
    raise NotImplementedError
  end

  # Returns { id:, url: } on success, { error: } on failure
  def post(text, reply_to: nil)
    raise NotImplementedError
  end

  protected

  def fetch_op_secret(op_path)
    output = `op read "#{op_path}" 2>&1`
    return output.strip if $?.success?
    
    puts "\n[1Password Error]: #{output.strip}"
    nil
  end
end
