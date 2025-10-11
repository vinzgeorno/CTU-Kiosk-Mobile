-- Sample data for testing the CTU Kiosk Admin app
-- Run this in your Supabase SQL Editor to populate test data

-- Insert sample tickets
INSERT INTO tickets (reference_number, facility, amount, visit_date, is_valid) VALUES
  ('TKT-2024-001', 'Swimming Pool', 50.00, NOW() - INTERVAL '2 hours', true),
  ('TKT-2024-002', 'Gymnasium', 30.00, NOW() - INTERVAL '1 day', true),
  ('TKT-2024-003', 'Library', 0.00, NOW() - INTERVAL '3 hours', true),
  ('TKT-2024-004', 'Swimming Pool', 50.00, NOW() - INTERVAL '5 days', true),
  ('TKT-2024-005', 'Computer Lab', 25.00, NOW() - INTERVAL '1 week', true),
  ('TKT-2024-006', 'Gymnasium', 30.00, NOW() - INTERVAL '2 weeks', false),
  ('TKT-2024-007', 'Swimming Pool', 50.00, NOW() - INTERVAL '3 weeks', true),
  ('TKT-2024-008', 'Auditorium', 100.00, NOW() - INTERVAL '1 month', true),
  ('TKT-2024-009', 'Library', 0.00, NOW() - INTERVAL '4 hours', true),
  ('TKT-2024-010', 'Computer Lab', 25.00, NOW() - INTERVAL '6 hours', true),
  ('TKT-2024-011', 'Gymnasium', 30.00, NOW() - INTERVAL '8 hours', true),
  ('TKT-2024-012', 'Swimming Pool', 50.00, NOW() - INTERVAL '2 days', true),
  ('TKT-2024-013', 'Auditorium', 100.00, NOW() - INTERVAL '3 days', false),
  ('TKT-2024-014', 'Library', 0.00, NOW() - INTERVAL '4 days', true),
  ('TKT-2024-015', 'Computer Lab', 25.00, NOW() - INTERVAL '6 days', true);

-- Verify the data
SELECT 
  facility,
  COUNT(*) as total_tickets,
  SUM(amount) as total_revenue,
  COUNT(CASE WHEN is_valid THEN 1 END) as valid_tickets
FROM tickets
GROUP BY facility
ORDER BY total_revenue DESC;
