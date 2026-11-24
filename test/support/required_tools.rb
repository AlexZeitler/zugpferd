module RequiredTools
  # CI sets up every tool the PDF tests need, so a missing one fails there.
  # Locally the test skips, because veraPDF is often missing on purpose.
  def require_tool(available, message)
    return if available

    flunk message if ci?
    skip message
  end

  def ci?
    !ENV["CI"].to_s.empty?
  end
end
