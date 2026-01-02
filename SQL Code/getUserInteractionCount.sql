SELECT user_id , count(user_id) FROM public.users_interaction
group by user_id
ORDER BY user_id desc